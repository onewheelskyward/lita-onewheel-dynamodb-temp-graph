require 'aws-sdk-dynamodb'
require 'aws-sdk-s3'
require 'gruff'

module Lita
  module Handlers
    class OnewheelDynamodbTempGraph < Handler
      config :api_key, required: true
      config :api_secret, required: true
      config :sensor_id, required: true
      config :table_name, required: true
      config :s3_bucket, required: true

      route /^tempgraph$/i,
            :generate_graph,
            command: true,
            help: { '!tempgraph' => 'temp graph!' }

      def generate_graph(response)
        Aws.config.update({ region: "us-west-2",
                            credentials: Aws::Credentials.new(Lita.config.api_key, Lita.config.api_secret)
                          })

        dynamodb = Aws::DynamoDB::Client.new
        s3 = Aws::S3::Client.new

        timestamp = Time.now.to_i

        begin
          params = {
              table_name: table_name,
              key_condition_expression: "#sensor_id = :sensor_id and unixtime between :start and :stop",
              expression_attribute_names: { "#sensor_id" => "sensor_id" },
              expression_attribute_values: {
                  ":sensor_id" => sensor_id,
                  ":start" => 1549734319,
                  ":stop" => timestamp
              }
          }

          result = dynamodb.query(params)
          unixtimes = []
          temps = []

          result.items.each do |item|
            unixtimes.push item['unixtime'].to_i
            temps.push item['temp'].to_f
          end

          # timing labels
          graph_label_points = unixtimes.count - 10
          iterator = unixtimes.count / 5
          labels = []
          #    labels.push = Time.at(unixtimes.min).strftime("%H:%M")

          4.times do |time|
            labels.push Time.at(unixtimes[iterator * time]).strftime("%H:%M")
          end

          labels.push Time.at(unixtimes.max).strftime("%H:%M")

          g = Gruff::Line.new
          g.title = 'TempSW'
          g.labels = { 0 => labels[0], iterator => labels[1], iterator*2 => labels[2], iterator*3 => labels[3], iterator*4 => labels[4] }
          g.data :sensor, temps

          object_key = "#{timestamp.to_s}.png"

          s3.put_object({
             body: g.to_blob(),
             bucket: Lita.config.s3_bucket,
             key: object_key,
          })

          response.reply "http://onewheelskyward-cdn.s3-website-us-west-2.amazonaws.com/#{object_key}"

        rescue Aws::DynamoDB::Errors::ServiceError, Aws::S3::Errors::ServiceError => e
          response.reply "Error found! #{e.message}"
        end
      end

    end

    Lita.register_handler(OnewheelDynamodbTempGraph)
  end
end
