

class BarclampSaltstack::Minion < Role
  def on_todo(nr)
    # return if we have data
    k = (nr.sysdata["saltstack"]["master"]["public_key"] rescue nil)
    d = (nr.sysdata["saltstack"]["master"]["ip"] rescue nil)
    n = (nr.sysdata["saltstack"]["minion"]["name"] rescue nil)
    return if d and k and n

    # Create saltstack metadata if needed.
    ssj = Jig.where(:name => "saltstack").first
    raise "Cannot load SaltStack Jig" unless ssj

    nr.with_lock do
      nr.sysdata = { "saltstack" => {
          "master" => {"ip" => ssj.server, "public_key" => ssj.key },
          "minion" => {"name" => nr.node.name }
        }
      }
      nr.save!
    end
  end
end

