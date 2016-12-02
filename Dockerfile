from nguyenphuongthanhf/docker-ansible2:latest

COPY src/ /ansible-tdd/ 
COPY docker-entrypoint.sh /

RUN easy_install pip
RUN pip install boto 

RUN apt-get install -y rubygems
RUN gem install serverspec 


ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/bin/bash"]
