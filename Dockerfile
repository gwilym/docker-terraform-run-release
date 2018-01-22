ARG terraformVersion
FROM hashicorp/terraform:${terraformVersion}
ARG terraformVersion
ENV TERRAFORM_VERSION="${terraformVersion}"

COPY include /opt/run-terraform-release
RUN /opt/run-terraform-release/build.sh
ENTRYPOINT ["/opt/run-terraform-release/run-terraform-release.sh"]
