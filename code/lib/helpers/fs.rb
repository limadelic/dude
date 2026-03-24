require_relative '../helpers'

class Helpers::FS
  def exist?(path) = File.exist?(path)

  def dir_exist?(path) = Dir.exist?(path)

  def read(path) = File.read(path)

  def write(path, data) = File.write(path, data)

  def children(path) = Dir.children(path)

  def symlink?(path) = File.symlink?(path)

  def readlink(path) = File.readlink(path)

  def pgrep(pattern) = `pgrep -f "#{pattern}"`.strip.split("\n").first&.to_i

  def pgrep_all(pattern) = `pgrep -f "#{pattern}"`.strip.split("\n").map(&:to_i).select(&:positive?)

  def orphaned?(pid) = `ps -p #{pid} -o ppid=`.strip.to_i == 1

  def kill(pid) = Process.kill('TERM', pid) rescue nil

  def newest_child(dir, suffix) = Dir.glob("#{dir}/*#{suffix}").max_by { |f| File.mtime(f) }

  def claude_cwds
    @claude_cwds ||= `pgrep -a claude`.strip.split("\n").filter_map do |pid|
      `lsof -p #{pid} 2>/dev/null`[/cwd\s+DIR\s+\S+\s+\S+\s+\S+\s+(.+)/, 1]
    end
  end
end
