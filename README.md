# lita-onewheel-dynamodb-temp-graph

[![Build Status](https://travis-ci.org/onewheelskyward/lita-onewheel-dynamodb-temp-graph.svg?branch=master)](https://travis-ci.org/onewheelskyward/lita-onewheel-dynamodb-temp-graph)
[![Coverage Status](https://coveralls.io/repos/github/onewheelskyward/lita-onewheel-dynamodb-temp-graph/badge.svg?branch=master)](https://coveralls.io/github/onewheelskyward/lita-onewheel-dynamodb-temp-graph?branch=master)

This is designed to plot dynamodb time series data collected from a temp sensor I have.

# Installation

Add lita-onewheel-dynamodb-temp-graph to your Lita instance's Gemfile:

`gem 'lita-onewheel-dynamodb-temp-graph'`

# Configuration

Add your AWS API keys to your lita_config.rb:

`config.handlers.onewheel_dynamodb_temp_graph.api_key`
`config.handlers.onewheel_dynamodb_temp_graph.api_secret`

# Usage

bot: !tempgraph
