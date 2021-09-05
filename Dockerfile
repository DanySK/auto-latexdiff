FROM danysk/docker-manjaro-texlive:24.20210905.1317
RUN yay-install ruby
RUN yay-install rubygems
ENV GEM_HOME=/rubygems/bin
ENV PATH="$GEM_HOME:$PATH"
COPY latexdiff.rb /usr/bin/latexdiff.rb
CMD [ "/usr/bin/latexdiff.rb", "/github/workspace/" ]
