require 'spec_helper'
require 'rake'
require 'stringio'

describe "mesh rake tasks" do # rubocop:disable RSpec/DescribeClass
  let(:rake) { Rake::Application.new }
  before do
    Rake.application = rake
    Rake.application.rake_require "mesh", [Rails.root.join('lib', 'tasks'), Rails.root.join('..', 'lib', 'tasks')], []
    Rake::Task.define_task(:environment) # rspec has loaded rails
  end

  describe "mesh:import" do
    let(:task_name) { "mesh:import" }
    let(:output) { StringIO.new }
    before do
      $stdout = output # rubocop:disable RSpec/ExpectOutput # TODO: Explore how to remove this disable
    end
    after :all do
      $stdout = STDOUT
    end
    it "has 'environment' as a prereq" do
      expect(rake[task_name].prerequisites).to include("environment")
    end
    it "requires $MESH_FILE to be set" do
      old_mesh_file = ENV.delete('MESH_FILE')
      rake[task_name].invoke
      output.seek(0)
      expect(output.read).to match(/Need to set \$MESH_FILE with path to file to ingest/)
      ENV['MESH_FILE'] = old_mesh_file
    end

    describe "create or update" do
      let(:input) { StringIO.new("*NEWRECORD\nUI = 5\nMH = test\n") }
      let(:term)  { Qa::SubjectMeshTerm.find_by_term_id(5) }

      before do
        ENV['MESH_FILE'] = "dummy"
        allow(File).to receive(:open).with("dummy").and_yield(input)
        rake[task_name].invoke
      end
      it "creates or update all records in the config file" do
        expect(term).not_to be_nil
        expect(term.term).to eq("test")
      end
    end
  end
end
