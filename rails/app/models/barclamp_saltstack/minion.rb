

class BarclampSaltstack::Minion < Role

  def sysdata(nr)
    {
      "saltstack" => {
        "minion" => { "name" => nr.node.name }
      }
    }
  end

  #
  # Once active, we should update the master to accept our key
  #
  def on_active(nr)
    the_name = nr.node.name
    the_key = Attrib.get("saltstack-minion_public_key", nr)

    Rails.logger.error("saltstack-minion: bad key for #{the_name}") unless the_key

    # GREG: All saltstack-master-mgmt-svc to add client/key.
  end

  def on_node_delete(n)
    Rails.logger.info("saltstack-minion: Updating for delete node #{n.name}")
    # GREG: This should call new saltstack-master mgmt service
  end

end

