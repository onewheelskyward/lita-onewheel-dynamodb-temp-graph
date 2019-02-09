require "lita"

require "lita/handlers/onewheel_dynamodb_temp_graph"

Lita::Handlers::OnewheelDynamodbTempGraph.template_root File.expand_path(
  File.join("..", "..", "templates"),
 __FILE__
)
