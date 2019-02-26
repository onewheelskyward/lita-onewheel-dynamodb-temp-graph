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

      route /^tempgraph\s+(.*)$/i,
            :generate_graph,
            command: true,
            help: { '!tempgraph 10m' => 'temp graph of the last 10 minutes!' }

      def generate_graph(response)

        now = Time.now
        timestamp = now.to_i
        start_time = now.to_i - 8000

        # Interval acquired
        interval = response.matches[0][0]
        if interval
          if m = interval.match(/(\d+)h/)
            start_time = timestamp - m[1].to_i * 3600
          end
          if m = interval.match(/(\d+)m/)
            start_time = timestamp - m[1].to_i * 60
          end
          if m = interval.match(/(\d+)s/)
            start_time = timestamp - m[1].to_i
          end
          if m = interval.match(/(\d+)d/)
            start_time = timestamp - m[1].to_i * 86400
          end

          Lita.logger.debug "Start time calculated to be #{start_time}"
        end

        dynamodb, s3 = config_aws

        begin
          temps, unixtimes = get_dynamo_results(dynamodb, timestamp, start_time)

          # Fix problems with the number of points:

          Lita.logger.debug "temps sent: #{temps.count}"
          Lita.logger.debug "unixtimes sent: #{unixtimes.count}"

          while temps.count > 100
            temps,right = temps.partition.each_with_index{ |el, i| i.even? }
            unixtimes,right = unixtimes.partition.each_with_index{ |el, i| i.even? }
          end

          # Lita.logger.debug "temps sent: #{temps}"
          # Lita.logger.debug "unixtimes sent: #{unixtimes}"
          Lita.logger.debug "temps sent: #{temps.count}"
          Lita.logger.debug "unixtimes sent: #{unixtimes.count}"

          # timing labels, break this array down into grid lines
          # that make sense on the graph.  Uncluttered.
          graph_label_points = unixtimes.count - 10
          iterator = unixtimes.count / 5

          labels = []

          4.times do |time|
            labels.push Time.at(unixtimes[iterator * time]).strftime("%H:%M")
          end

          labels.push Time.at(unixtimes.max).strftime("%H:%M")

          # g = Gruff::Bezier.new
          g = Gruff::Line.new
          g.title = 'TempSW'
          g.labels = {
              0 => labels[0],
              iterator => labels[1],
              iterator*2 => labels[2],
              iterator*3 => labels[3],
              iterator*4 => labels[4]
          }
          g.data :sensor, temps

          # plop it into the public s3 bucket.
          image_url = plop_in_s3(g, s3, timestamp)
          response.reply image_url

        rescue Aws::DynamoDB::Errors::ServiceError, Aws::S3::Errors::ServiceError => e
          response.reply "Error found! #{e.message}"
        end
      end

      private

      def plop_in_s3(g, s3, timestamp)
        object_key = "#{timestamp.to_s}.png"

        s3.put_object({
            body: g.to_blob(),
            bucket: config.s3_bucket,
            key: object_key,
        })

        image_url = "http://#{config.s3_bucket}.s3-website-us-west-2.amazonaws.com/#{object_key}"
      end

      def get_dynamo_results(dynamodb, end_time, start_time = Time.now.to_i)
        params = {
            table_name: config.table_name,
            key_condition_expression: "#sensor_id = :sensor_id and unixtime between :start and :stop",
            expression_attribute_names: {"#sensor_id" => "sensor_id"},
            expression_attribute_values: {
                ":sensor_id" => config.sensor_id,
                ":start" => start_time,
                ":stop" => end_time
            }
        }

        result = dynamodb.query(params)
        unixtimes = []
        temps = []

        result.items.each do |item|
          unixtimes.push item['unixtime'].to_i
          temps.push item['temp'].to_f
        end

        return temps, unixtimes
      end

      def config_aws
        Aws.config.update(
          {region: "us-west-2",
           credentials: Aws::Credentials.new(config.api_key, config.api_secret)
          })

        dynamodb = Aws::DynamoDB::Client.new
        s3 = Aws::S3::Client.new

        return dynamodb, s3
      end

    end

    Lita.register_handler(OnewheelDynamodbTempGraph)
  end
end
