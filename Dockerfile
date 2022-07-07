FROM alpine:3.16.0

ARG TARGETPLATFORM
ENV TERRAFORM_VERSION 1.1.9
ENV TERRAGRUNT_VERSION 0.36.10
ENV YQ_VERSION 4.25.2

RUN apk add --no-cache \
  git \
  curl \
  bash \
  gcompat \
  jq \
  openssh-keygen \
  sudo \
  shadow \
  openssl \
  && rm -rf /var/cache/apk/*

RUN curl -Lso /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_$(if [[ "$TARGETPLATFORM" == "linux/arm64" ]]; then echo "arm64"; else echo "amd64"; fi).zip && \
    mkdir -p /tmp/terraform && \
    cd /tmp/terraform && \
    unzip /tmp/terraform.zip && \
    mv ./terraform /usr/local/bin && \
    cd - && \
    rm -rf /tmp/terraform && \
    rm /tmp/terraform.zip

RUN curl -Lso /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_$(if [[ "$TARGETPLATFORM" == "linux/arm64" ]]; then echo "arm64"; else echo "amd64"; fi)" && chmod +x /usr/local/bin/yq

RUN curl -sLo ./terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_$(if [[ "$TARGETPLATFORM" == "linux/arm64" ]]; then echo "arm64"; else echo "amd64"; fi) && \
    chmod +x ./terragrunt && \
    mv ./terragrunt /usr/bin/terragrunt

##################################
# User setup
##################################

# Configure sudoers so that sudo can be used without a password
RUN groupadd --force sudo && \
    chmod u+w /etc/sudoers && \
    echo "%sudo   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV HOME /home/devops

# Create devops user
RUN useradd -u 10000 -g root -G sudo -d ${HOME} -m devops && \
    usermod --password $(echo password | openssl passwd -1 -stdin) devops && \
    mkdir -p /workspaces && \
    chown -R 10000:0 /workspaces

USER devops
WORKDIR ${HOME}

ENTRYPOINT ["/bin/bash"]
