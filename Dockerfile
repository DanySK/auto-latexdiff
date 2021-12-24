FROM danysk/docker-manjaro-texlive-ruby:5.20211224.1044
COPY latexdiff.rb /usr/bin/latexdiff.rb
RUN ruby -c /usr/bin/latexdiff.rb
ENTRYPOINT [ "/usr/bin/latexdiff.rb" ]
