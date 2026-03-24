require_relative '../dudes'

class Dudes::Abide
  def dead?(pids, pid_alive, wip_items, has_abide_task)
    return true if pids.empty? || !pid_alive
    has_wip = wip_items.any? { |item| item['status'] == 'wip' }
    has_wip && !has_abide_task
  end
end
