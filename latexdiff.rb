directory = ARGV[0] || '.'

latex_roots = Dir["#{directory}/**/*.tex"]
    .map { |name| name.gsub('//', '/') }
    .reject { |file| IO.readlines(file).any? { |line| line =~ /^%\s*!\s*[Tt][Ee][Xx]\s*[Rr][Oo]{2}[Tt]\s*=.*$/ } }
puts "The following LaTeX root files were found:"
puts latex_roots
@builders = []

def verify_command(command_name, option = command_name)
    `which tectonic`
    if $?.exitstatus == 0 then
        puts "#{command_name} detected"
        @builders += ["--#{option}"]
        true
    else
        puts "#{command_name} not installed."
        false
    end
end

verify_command('tectonic')
verify_command('latexmk')
verify_command('lualatex')
verify_command('xelatex')
if verify_command('pdflatex', '') then
    @builders += ['--bibtex', '--biber']
end

def run_in_directory(directory, command)
    `
    cd #{directory}
    >&2 echo inside #{directory}: running #{command}
    #{command}
    `
end

for latex_root in latex_roots
    directory, file = /(.*)\/(.*)$/.match(latex_root).captures
    tags = run_in_directory(directory, 'git show-ref -d --tags | cut -b 42-')
        .split.select{ |it| it.end_with?('^{}')  }
        .map { |it| it.gsub(/^refs\/tags\/(.+)\^\{\}$/, '\1') }
    puts "detected tags #{tags} for file #{latex_root}"
    for tag in tags
        for builder in @builders
            puts run_in_directory(
                directory,
                "git latexdiff #{tag}"\
                " --main #{file}"\
                " --ignore-latex-errors --no-view --latexopt -shell-escape -t CFONTCHBAR"\
                " #{builder}"\
                " -o #{directory}/#{file}-wrt-#{tag}#{builder}.pdf"
            )
        end
    end
end
