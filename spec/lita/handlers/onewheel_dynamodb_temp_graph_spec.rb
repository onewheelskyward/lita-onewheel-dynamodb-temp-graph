require 'spec_helper'
require 'timecop'

describe Lita::Handlers::OnewheelDynamodbTempGraph, lita_handler: true do
  # it { is_expected.to route_command('aqi') }

  def mock(file)
    mock = File.open("spec/fixtures/#{file}.json").read
    allow(RestClient).to receive(:get) { mock }
  end

  before do
  end

  # it 'queries the aqi' do
  #   mock('Output')
  #   send_command 'aqi'
  #   expect(replies.last).to include("AQI for Portland, OR, USA, ⚠️ 08Moderate ⚠️ pm25: 0876  µg/m³(est): 23.99  pm10: 0340  updated 0860 minutes ago.  14(http://aqicn.org/city/usa/oregon/government-camp-multorpor-visibility/)")
  # end
end
