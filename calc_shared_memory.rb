#!/usr/bin/env ruby

def get_tgid(pid)
    begin
        File.open("/proc/#{pid}/stat"){|f|f.each{|l|return l.split[5].to_i}}
    rescue
        puts "No such process #{pid}"
        exit 1
    end
end

def prg_name_to_pid(prg_name)
    Dir.glob("/proc/*/cmdline") { |f|
        File.open(f) { |txt|
            txt.each { |line|
                next if line.include?(__FILE__)
                if line.include?(prg_name)
                    return f.gsub(/\/proc\/(.*)\/cmdline/, '\1')
                end
            }
        }
    }
end

def generate_pid_list(tdid)
    pid_list = []
    Dir.glob("/proc/*/stat") { |f|
        next if f.to_s == "/proc/net/stat"
        File.open(f) { |txt|
            txt.each { |l|
                if tdid.to_s == l.split[5]
                    pid_list << f.gsub(/\/proc\/(.*)\/stat/, '\1')
                end
            }
        }
    }
    pid_list
end

def calc_shared_memory_rate(pid_list, _pid)
    rss = share = 0
    cmd = ""
    pid_list.each { |pid|
        File.open("/proc/#{pid}/cmdline") {|f| f.each {|l| cmd = l}}
        File.open("/proc/#{pid}/smaps") { |f|
            f.each { |line|
                rss += line.split[1].to_i if line.include?("Rss")
                share += line.split[1].to_i if line.include?("Shared")
            }
            if _pid == pid
                puts "\e[31m#{pid}: #{((share.to_f/rss)*100).round(2)}[%] (#{share}/#{rss}) #{cmd}\e[0m"
            else
                puts "#{pid}: #{((share.to_f/rss)*100).round(2)}[%] (#{share}/#{rss}) #{cmd}"
            end
            rss = share = 0
        }
    }

end

def main(argv)
    if Process::UID.eid != 0
        puts "Please run as root user"
        exit 1
    end

    pid = 0
    if argv =~ /^[0-9]+$/
        pid = argv
    else
       pid = prg_name_to_pid argv
    end

    pid_list = generate_pid_list get_tgid pid
    calc_shared_memory_rate pid_list, pid
end

main ARGV[0]
