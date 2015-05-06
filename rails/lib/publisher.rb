# Copyright 2015, Greg Althaus
# 
# Licensed under the Apache License, Version 2.0 (the "License"); 
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at 
# 
#  http://www.apache.org/licenses/LICENSE-2.0 
# 
# Unless required by applicable law or agreed to in writing, software 
# distributed under the License is distributed on an "AS IS" BASIS, 
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
# See the License for the specific language governing permissions and 
# limitations under the License. 
# 
#

class Publisher
  @@connection = nil
  @@success = false
  @@semaphore = Mutex.new

  def self.get_channel
    connection = nil
    @@semaphore.synchronize do
      unless @@connection
        # Lookup amqp service and build url for bunny
        s = ConsulAccess.getService('amqp-service')
        if s == nil || s.ServiceAddress == nil
          return nil
        end
        addr = IP.coerce(s.ServiceAddress)
        hash = {}
        hash[:user] = 'crowbar'
        hash[:pass] = 'crowbar'
        if addr.v6?
          hash[:host] = "[#{addr.addr}]"
        else
          hash[:host] = addr.addr
        end
        hash[:vhost] = '/opencrowbar'
        hash[:port] = s.ServicePort.to_i

        Rails.logger.debug("Attempting to connection to AMQP service: #{hash}")
        @@connection = Bunny.new(hash)
        @@connection.start
      end
      connection = @@connection
    end
    connection.create_channel
  end

  def self.close_channel(channel)
    begin
      channel.close if channel
    rescue Exception => e
      Rails.logger.fatal("publish_event close channel failed: #{e.message}") if @@success
    end
    @@semaphore.synchronize do
      begin
        @@connection.close if @@connection
      rescue Exception => e
        Rails.logger.fatal("publish_event close connection failed: #{e.message}") if @@success
      ensure
        @@connection = nil
      end
    end
  end

  # In order to publish message we need a exchange name.
  # Note that RabbitMQ does not care about the payload -
  # we will be using JSON-encoded strings
  def self.publish_event(who, type, message = {})
    channel = nil
    begin
      channel = self.get_channel
      unless channel
        Rails.logger.fatal("publish_event: failed to create channel") if @@success
        return
      end
      @@success = true
      x = channel.topic("opencrowbar")
      # and simply publish message
      x.publish(message.to_json, :routing_key => "#{who}.#{type}")
    rescue Exception => e
      Rails.logger.fatal("publish_event failed: #{e.message}") if @@success
      self.close_channel(channel)
    end
  end

end

