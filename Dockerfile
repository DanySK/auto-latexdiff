FROM danysk/docker-manjaro-texlive:47.20211114.1558
RUN yay-install ruby
RUN yay-install rubygems
ENV GEM_HOME=/rubygems/bin
ENV PATH="$GEM_HOME:$PATH"
COPY latexdiff.rb /usr/bin/latexdiff.rb
CMD [ "/usr/bin/latexdiff.rb", "/github/workspace/" ]
