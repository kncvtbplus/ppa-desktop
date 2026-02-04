## PPA Desktop — Overview, structure and usage

The PPA Desktop is a Java Spring Boot web application that guides the Patient Pathway Analysis (PPA) process end‑to‑end: uploading data, mapping variables, and generating PPA outputs. This repository contains a prebuilt application (`application.jar`) and a `Procfile` to run the app as a web process.

## Architecture and tech stack

- **Platform**: Java (Spring Boot, embedded Tomcat)
- **Web layer**: Spring MVC, Thymeleaf extras, static assets using jQuery EasyUI
- **Security**: Spring Security with custom handlers/listeners
- **Data**: Spring Data JPA (Hibernate), PostgreSQL dialect
- **Files/Cloud**: AWS S3 for scripts, uploads, and output
- **R integration**: Rserve (external) and Renjin libraries for R script execution

### Runtime structure (from `application.jar`)

- `BOOT-INF/classes/`
  - `application.properties`, `messages.properties`
  - `static/` — JS/CSS/images (jQuery EasyUI, etc.)
  - `templates/` — Thymeleaf templates (if present)
  - `com/linksbridge/ppa/` (original Java package namespace used in the JAR)
    - core: `Application` (Spring Boot main)
    - config: `WebMvcConfiguration`, `WebSecurityConfiguration`, `RefreshSessionInterceptor`
    - security: custom authentication/authorization handlers
    - controllers: `controller/DataController`, `RestControllerAdvice`
    - domain: `model/*` (e.g., `Ppa`, `PpaSector`, `Metric`, `User`, `Account`, …)
    - persistence: `repository/*` (Spring Data repositories)
    - users: `user/MyUserDetailsService`, `MyUserDetails`
    - utilities and Thymeleaf dialect extensions

The PPA Desktop was originally built under the `com.linksbridge.ppa` namespace and is now fully maintained and distributed by **KNCV TB Plus**.

## Functional overview

The application supports a step‑by‑step PPA workflow (as reflected in `messages.properties`):

- **Team spaces & user management**: create spaces, invite/expel users, manage roles.
- **PPA management**: PPAs per team, duplicate/delete, national/subnational aggregation.
- **Data sources**: upload (.csv/.dta), manage, subset, apply sample weights.
- **Identify variables**:
  - Global variables (facility type, health sector, geography)
  - Service availability variables per metric
- **Mapping**:
  - Define health sectors & levels and map data values
  - Define geographies and map data source values
- **Output**: generate, preview, and download PPA outputs.
- **Email flows**: registration/confirm email, invitations, password reset.

## Configuration (environment variables)

Key settings (see `application.properties`) are provided via environment variables:

- **PostgreSQL**:
  - `RDS_HOSTNAME`, `RDS_PORT`, `RDS_USERNAME`, `RDS_PASSWORD`
  - JDBC: `jdbc:postgresql://${RDS_HOSTNAME}:${RDS_PORT}/ppa`
- **AWS S3**:
  - `S3_BUCKET` — bucket name
  - Paths: `s3.rscript.key=script/Auto.PPA.UI.R`, `s3.userfile.directory=datasource`, `s3.output.directory=output`
- **Rserve**:
  - `RSERVE_HOST`, `RSERVE_PORT`
- **Sessions and uploads**:
  - `server.servlet.session.timeout=3600`
  - Upload limits: 10 GB (max file/request), temp directory via `spring.servlet.multipart.location`
- **Other**:
  - `messages.properties.path=messages.properties`
  - Token key and timeouts for links (confirm/invite/reset)

## Requirements

- Java Runtime (JRE/JDK) installed
- Reachable PostgreSQL instance with database `ppa`
- Reachable Rserve endpoint
- AWS credentials configured to access `S3_BUCKET`

## Run the application

Local start (after setting environment variables):

```bash
java -Xms2g -Xmx14g -Djava.io.tmpdir=%TEMP% -jar application.jar
```

Via `Procfile` (e.g., on Heroku/Procfile‑based platforms):

```
web: java -Xms2g -Xmx14g -Djava.io.tmpdir=/var/tmp -jar application.jar
```

By default the app runs on the Spring Boot port (on PaaS often via the `PORT` env var).

## Data layer and migrations

The JPA/Hibernate configuration uses the PostgreSQL9 dialect and the `public` schema. Migrations/tooling are not visible in this JAR; schema and migration management are handled externally (or in the original source/build).

## Repository scope

This folder contains the built artifacts (`application.jar`) but not the original source code or build scripts. To change logic/UI you will need the source; runtime configuration is possible via the environment variables above.

## Support

Contact the team if you need assistance configuring RDS/S3/Rserve or setting up Procfile‑based deployments.

### Infrastructure (AWS)

The repository now includes infrastructure‑as‑code under `ppa-infra/` (moved into this project for convenience). It provisions the application stack in AWS using CloudFormation/SAM and configures CloudFront and Route53.

- Components:
  - `ppa-infra/backend.yaml`: Elastic Beanstalk environment, RDS PostgreSQL, EC2 for Rserve, S3 bucket, security groups, IAM, DNS records.
  - `ppa-infra/cloudfront-eb.yaml`: CloudFront distribution and Route53 A/alias records.
  - `ppa-infra/Makefile`: entrypoints for deploying dev/accept/prod and populating S3 content.
- Environments: development, accept, production.
- Prerequisites: AWS CLI v2, AWS SAM CLI, an existing Beanstalk application named `ppa`, certificate in ACM for `ppa.kncvtbc.org`.

Deploy development environment (from `ppa-infra/`):

```bash
make development
```

This runs the EB stack, CloudFront, and content restore targets shown below:

```92:110:ppa-infra/Makefile
ppa-development-ng-cloudfront:
	aws cloudformation deploy \
	 	--no-fail-on-empty-changeset \
		--template-file cloudfront-eb.yaml \
		--stack-name $@ \
		--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
		--role-arn arn:aws:iam::365027787595:role/ppa-infra-cfn \
		--parameter-overrides \
			ElasticBeanstalkEnvironmentName=development-ng \
			ACMCertificateArn=$(CERT) \
			DomainName=ppa.kncvtbc.org 
```

Key environment variables injected into the app servers are defined in the EB settings of the backend stack:

```450:503:ppa-infra/backend.yaml
      - Namespace: aws:elasticbeanstalk:application:environment
        OptionName: RDS_HOSTNAME
        Value: 
          Fn::GetAtt:
          - DatabaseInstance
          - Endpoint.Address
      - Namespace: aws:elasticbeanstalk:application:environment
        OptionName: RSERVE_HOST
        Value:
          Fn::GetAtt:
          - RServeInstance
          - PrivateDnsName
      - Namespace: aws:elasticbeanstalk:application:environment
        OptionName: S3_BUCKET
        Value:
          Ref: ApplicationS3Bucket
```

Notes and safety:
- Production should not be recreated casually; dev can be created/destroyed on demand.
- Use temporary credentials or a role‑based environment (e.g., Cloud9) to deploy; avoid long‑lived secrets.
- DNS and certificates are managed in Route53/ACM for `ppa.kncvtbc.org` and subdomains.

### Deploy from Cloud9

For step‑by‑step Cloud9 instructions, validation commands, and a parameter checklist, see `ppa-infra/README.md`. Quick start:

```bash
cd ppa-infra
make development   # provisions EB, RDS, Rserve, S3, CloudFront + DNS
```


