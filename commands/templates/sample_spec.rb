require_relative 'spec_helper'

describe port(6379) do
  it { should be_listening.on('0.0.0.0').with('tcp') }
end
