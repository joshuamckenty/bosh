module Bosh::Aws
  class Destroyer
    def initialize(ui, config, rds_destroyer)
      @ui = ui
      @credentials = config['aws']
      @rds_destroyer = rds_destroyer
    end

    def ensure_not_production!
      raise "#{ec2.instances_count} instance(s) running. This isn't a dev account (more than 20) please make sure you want to do this, aborting." if ec2.instances_count > 20
      raise "#{ec2.volume_count} volume(s) present. This isn't a dev account (more than 20) please make sure you want to do this, aborting."      if ec2.volume_count > 20
    end

    def delete_all_elbs
      elb = Bosh::Aws::ELB.new(@credentials)
      elb_names = elb.names
      if elb_names.any? && @ui.confirmed?("Are you sure you want to delete all ELBs (#{elb_names.join(', ')})?")
        elb.delete_elbs
      end
    end

    def delete_all_ec2
      formatted_names = ec2.instance_names.map { |id, name| "#{name} (id: #{id})" }

      unless formatted_names.empty?
        @ui.say("THIS IS A VERY DESTRUCTIVE OPERATION AND IT CANNOT BE UNDONE!\n".make_red)
        @ui.say("Instances:\n\t#{formatted_names.join("\n\t")}")

        if @ui.confirmed?('Are you sure you want to terminate all terminatable EC2 instances and their associated non-persistent EBS volumes?')
          @ui.say('Terminating instances and waiting for them to die...')
          if !ec2.terminate_instances
            @ui.say('Warning: instances did not terminate yet after 100 retries'.make_red)
          end
        end
      else
        @ui.say('No EC2 instances found')
      end
    end

    def delete_all_ebs
      if ec2.volume_count > 0
        @ui.say("THIS IS A VERY DESTRUCTIVE OPERATION AND IT CANNOT BE UNDONE!\n".make_red)
        @ui.say("It will delete #{ec2.volume_count} EBS volume(s)")

        if @ui.confirmed?('Are you sure you want to delete all unattached EBS volumes?')
          ec2.delete_volumes
        end
      else
        @ui.say('No EBS volumes found')
      end
    end

    def delete_all_rds
      @rds_destroyer.delete_all
    end

    private

    def ec2
      @ec2 ||= Bosh::Aws::EC2.new(@credentials)
    end
  end
end