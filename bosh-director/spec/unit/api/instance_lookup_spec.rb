require 'spec_helper'
require 'bosh/director/api/instance_lookup'

module Bosh::Director
  module Api
    describe InstanceLookup do
      let(:instance) { instance_double('Bosh::Director::Models::Instance') }
      let(:deployment_lookup) { instance_double('Bosh::Director::Api::DeploymentLookup') }
      subject(:instance_lookup) { InstanceLookup.new }

      before do
        DeploymentLookup.stub(new: deployment_lookup)
      end

      describe '.by_id' do
        let(:instance_id) { 5 }

        before do
          Models::Instance.stub(:[]).and_return(instance)
        end

        it 'finds instance for id' do
          expect(instance_lookup.by_id(instance_id)).to eq instance
        end

        context 'no instance exists for id' do
          let(:instance) { nil }

          it 'raises' do
            expect {
              instance_lookup.by_id(instance_id)
            }.to raise_error(InstanceNotFound, "Instance 5 doesn't exist")
          end
        end
      end

      describe '.by_attributes' do
        let(:deployment) { instance_double('Bosh::Director::Models::Deployment', id: 1, name: 'foobar') }
        let(:job_name) { 'my_job' }
        let(:job_index) { '6' }

        before do
          filter_attributes = { deployment_id: deployment.id, job: job_name, index: job_index }
          Models::Instance.stub(:find).with(filter_attributes).and_return(instance)
          deployment_lookup.stub(:by_name).with(deployment.name).and_return(deployment)
        end

        it 'finds instance based on attribute vector' do
          expect(instance_lookup.by_attributes(deployment.name, job_name, job_index)).to eq instance
        end

        context 'no instance exists for attribute vector' do
          let (:instance) { nil }

          it 'raises' do
            expect {
              instance_lookup.by_attributes(deployment.name, job_name, job_index)
            }.to raise_error(InstanceNotFound, "`#{deployment.name}/#{job_name}/#{job_index}' doesn't exist")
          end
        end
      end

      describe '.by_filter' do
        let(:instances) { [instance] }
        let(:filter) { { id: 5 } }

        before do
          Models::Instance.stub(:filter).with(filter).and_return(double('Dataset', all: instances))
        end

        it 'finds only instances that match sql filter' do
          expect(instance_lookup.by_filter(filter)).to eq instances
        end

        context 'no instances exist for sql filter' do
          let(:instances) { [] }

          it 'raises' do
            expect {
              instance_lookup.by_filter(id: 5)
            }.to raise_error(InstanceNotFound, "No instances matched #{filter.inspect}")
          end
        end
      end

      describe '.find_all' do
        let(:instances) { [instance] }

        before do
          Models::Instance.stub(all: instances)
        end

        it 'pulls all instances' do
          expect(instance_lookup.find_all).to eq instances
        end
      end
    end
  end
end
