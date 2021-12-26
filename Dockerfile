FROM danysk/docker-manjaro-texlive-ruby:8.20211226.1727
COPY latexdiff.rb /usr/bin/latexdiff.rb
RUN ruby -c /usr/bin/latexdiff.rb
ENTRYPOINT [ "/usr/bin/latexdiff.rb" ]
