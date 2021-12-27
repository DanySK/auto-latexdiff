FROM danysk/docker-manjaro-texlive-ruby:9.20211226.2202
COPY latexdiff.rb /usr/bin/latexdiff.rb
RUN ruby -c /usr/bin/latexdiff.rb
ENTRYPOINT [ "/usr/bin/latexdiff.rb" ]
