FROM danysk/docker-manjaro-texlive-ruby:10.20211227.0521
COPY latexdiff.rb /usr/bin/latexdiff.rb
RUN ruby -c /usr/bin/latexdiff.rb
ENTRYPOINT [ "/usr/bin/latexdiff.rb" ]
