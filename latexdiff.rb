#!/usr/bin/env ruby

require 'tmpdir'

BEGIN {
    def group(name)
        puts "::group::#{name}"
    end
    
    def endgroup
        puts '::endgroup::'
    end
    
    group('Auto LaTeX-diff Action')
}
END { endgroup }

def test_installation_of(command, name = command)
    group("Test availability of #{command}")
    `#{command} --help`
    endgroup
    unless $?.exitstatus then
        raise "'#{name}' is not installed in the local system, cannot continue."
    end
end

def split_directory_and_file(file)
    /(.*\/)(.*)$/.match(file).captures
end

test_installation_of('latexdiff')

# Bind arguments
fail_on_error = (ARGV[0] || 'true').to_s == 'true'

directory = ARGV[1] || '.'
directory = /^(.+?)\/?$/.match(directory).captures[0]

files = (ARGV[2] || '**/*.tex')
puts "Provided raw file patterns:\n#{files}"
files = files.split(/\R/)
puts "Provided file patterns:\n#{files}"
files = files.flat_map{ |glob| Dir["#{directory}/#{glob}"] }
    .map { |name| name.gsub('//', '/') }
puts "Files matching all patterns: #{files}"

method = ARGV[3] || 'CFONTCHBAR'
puts "Diff method: #{method}"

use_magic_comments = (ARGV[4] || 'true').to_s.downcase == 'true'
magic_comment = /^\s*%\s*!\s*[Tt][Ee][Xx]\s*[Rr][Oo]{2}[Tt]\s*=\s*(.*?)\s*$/
if use_magic_comments then
    puts "Magic comment analysis started."
    files = files.map { |file|
        match = IO.readlines(file).lazy
            .map { |line| line.match(magic_comment) }
            .reject(&:nil?)
            .first
        if match.nil? then
            puts "File #{file} has no magic comment and will be considered a root."
            file
        else
            local_directory, _ = split_directory_and_file(file)
            actual_root = "#{local_directory}#{match[1]}"
            puts "File #{file} has a magic comment pointing to #{actual_root}"
            actual_root
        end
    }.uniq.reject { |file_path| file_path.empty? }
    puts "After analysis, the list of LaTeX roots is: #{files}"
else 
    puts "Magic comment analysis disabled."
end

def run_in_directory(directory, command)
    puts "Running => cd '#{directory}' && #{command}"
    `
    cd #{directory}
    #{command}
    `
end

tag_filters = (ARGV[5] || '.*').split(/\R/).map { |regex| /#{regex}/ }
include_lightweight = (ARGV[6] || 'false').to_s.downcase == 'true'

@successful = []

def set_output()
    success_list = @successful.join('%0A') # See: https://github.community/t/set-output-truncates-multiline-strings/16852/3
    puts "Setting output to: #{success_list}"
    puts "::set-output name=results::#{success_list}"
end

def ensure_success(operation, output)
    if $?.exitstatus != 0 then
        puts "ERROR in #{operation}:"
        puts output.split(/\R/).map { |line| "#{operation}: #{line}" }.join("\n")
        exit $?.exitstatus
    end
end

for latex_root in files
    puts "Running on file #{latex_root}"
    local_directory, file = /(.*\/)(.*)$/.match(latex_root).captures
    tags = run_in_directory(local_directory, 'git show-ref -d --tags | cut -b 42-').split
        .map { |it| it.gsub(/^refs\/tags\/(.+)$/, '\1') }.uniq
    puts "Detected tags ('^{}' indicates annotated tags): #{tags}"
    if include_lightweight then
        tags = tags.reject { |it| it.end_with?('^{}') }
        puts "Lightweight tags enabled"
    else
        tags = tags.select { |it| it.end_with?('^{}') }.map { |it| it[0..-4]  }
        puts "Lightweight tags disabled"
    end
    puts "tag set reduced to #{tags}, filtering patterns"
    tags = tags.select { |tag| tag_filters.any? { |filter| filter.match?(tag) } }
    puts "tag set finally reduced to #{tags}"
    for tag in tags
        puts "::group::Producing diff for #{file}: ${tag} => current"
        begin
            file_name = /^(.*?)(\.[\d\w]*)?$/.match(file)[1]
            Dir.mktmpdir(["auto-latexdiff", file_name]) { |temp_dir|
                puts "Created temporary directory => mkdir -p '#{temp_dir}'"
                clone = run_in_directory(local_directory, "git clone . '#{temp_dir}'")
                ensure_success("git clone", clone)
                checkout = run_in_directory(temp_dir, "git checkout '#{tag}' .")
                ensure_success("git checkout", checkout)
                output_file = "#{file_name}-wrt-#{tag}.tex"
                latexdiff = run_in_directory(
                    local_directory,
                    "latexdiff --flatten -t '#{method}' '#{temp_dir}/#{file}' '#{file}' 2>&1 > '#{output_file}'",
                )
                puts "Latexdiff terminates with output: #{latexdiff}"
                destination = "#{local_directory}#{output_file}"
                if use_magic_comments then
                    puts "Remove magic comments included in #{destination} by flattening"
                    text = File.read(destination)
                    filtered_contents = text.gsub(magic_comment, '% <redacted magic comment pointing the root to \1>')
                    File.open(destination, "w") {|file| file.puts filtered_contents }
                end
                puts "chmod 666 '#{destination}'"
                `chmod 666 '#{destination}'` # Container runs as root
                if $?.exitstatus != 0 then
                    puts "latexdiff failed with error code #{$?.exitstatus}"
                    if fail_on_error then
                        ensure_success('latexdiff', latexdiff)
                    end
                end
            }
        ensure
            puts '::endgroup::'
        end
    end
end
set_output()
