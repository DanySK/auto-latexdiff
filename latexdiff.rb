#!/usr/bin/env ruby

BEGIN { puts '::group::Auto LaTeX-diff Action' }
END { puts '::endgroup::' }

def test_installation_of(command, name = command)
    `#{command} --help`
    unless $?.exitstatus then
        raise "'#{name}' is not installed in the local system, cannot continue."
    end
end

def split_directory_and_file(file)
    /(.*\/)(.*)$/.match(file).captures
end

test_installation_of('git latexdiff')

# Bind arguments
bibtex = ARGV[0] || 'default'
if ['bibtex', 'biber'].include?(bibtex) then
    bibtex = "--#{bibtex}"
else
    bibtex = ''
end

builder = ARGV[1] || 'latexmk'
supported_builders = ['latexmk', 'tectonic', 'pdflatex', 'xelatex', 'lualatex']
unless supported_builders.include?(builder) then
    raise "Unknown build command '#{builder}'', expected one of: #{supported_builders}"
end
supported_builders = ([builder] + supported_builders).uniq
supported_builders.each { |builder| test_installation_of(builder) }

directory = ARGV[2] || '.'
directory = /^(.+?)\/?$/.match(directory).captures[0]

files = (ARGV[3] || '**/*.tex')
    .split('/R')
    .flat_map{ |glob| Dir["#{directory}/#{glob}"] }
    .map { |name| name.gsub('//', '/') }
puts "Files matching all patterns: #{files}"

method = ARGV[4] || 'CFONTCHBAR'
puts "Diff method: #{method}"

use_magic_comments = (ARGV[5] || 'true').to_s.downcase == 'true'
if use_magic_comments then
    puts "Magic comment analysis started."
    magic_comment = /^\s*%\s*!\s*[Tt][Ee][Xx]\s*[Rr][Oo]{2}[Tt]\s*=\s*(.*?)\s*$/
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
    puts "Running '#{command}' in '#{directory}'"
    `
    cd #{directory}
    #{command}
    `
end

tag_filters = (ARGV[6] || '.*').split(/\R/).map { |regex| /#{regex}/ }
include_lightweight = (ARGV[7] || 'false').to_s.downcase == 'true'

latex_options = (ARGV[8] || '-shell-escape').split(/\R/)
    .map{ |option| "--latexopt #{option}" }
    .join(" ")

@successful = []

def set_output()
    success_list = @successful.join('%0A') # See: https://github.community/t/set-output-truncates-multiline-strings/16852/3
    puts "Setting output to: #{success_list}"
    puts "::set-output name=results::#{success_list}"
end

for latex_root in files
    puts "Running on file #{latex_root}"
    local_directory, file = /(.*\/)(.*)$/.match(latex_root).captures
    relative_directory = local_directory.gsub(directory, '').gsub(/^\//, '')
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
    puts "tag set reduced to #{tags}"
    for tag in tags
        working_builder = supported_builders.lazy
            .map { |builder|
                output_file = "#{file.gsub('.tex', '')}-wrt-#{tag}-#{builder}.pdf"
                output = "#{local_directory}#{output_file}"
                actual_builder = if builder == 'pdflatex' then '' else "--#{builder}" end
                command =
                "git latexdiff #{tag}"\
                " --main #{file}"\
                " -o #{output}"\
                ' --ignore-latex-errors --no-view'\
                " #{latex_options}"\
                " -t #{method}"\
                " #{actual_builder}"\
                " #{bibtex} 2>&1"
                output = run_in_directory(local_directory, command)
                [builder, $?.exitstatus, output]
            }
            .each { |builder, exit_status, output|
                if (exit_status == 0) then 
                    puts "Builder #{builder} succeded"
                else
                    puts "Builder #{builder} failed with exist status #{exit_status}"
                    puts 'Output for the failure:'
                    puts output.split(/\R/).map { |line| "#{builder}: #{line}" }.join("\n")
                end
            }
            .find { |builder, exit_status, output| exit_status == 0 }
        if working_builder.nil? then
            puts "Terminating action: none of the builders succeded."
            set_output()
            exit $?.exitstatus
        else
            puts "#{output_file} compiled successfully!"
            @successful << "#{relative_directory}#{output_file}"
        end
    end
end
set_output()
