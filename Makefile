include .env

SCHEMA=`cat schema.graphql`

clean:
	rm -rf dist

dependencies:
	go get github.com/SlyMarbo/rss
	go get github.com/axgle/mahonia

build: clean
	GOOS=linux go build -o dist/handler ./...

configure:
	aws s3api create-bucket \
		--bucket $(AWS_BUCKET_NAME) \
		--region $(AWS_REGION)

package: build
	@aws cloudformation package \
		--template-file template.yml \
		--s3-bucket $(AWS_BUCKET_NAME) \
		--region $(AWS_REGION) \
		--output-template-file package.yml

deploy:
	@aws cloudformation deploy \
		--template-file package.yml \
		--region $(AWS_REGION) \
		--capabilities CAPABILITY_IAM \
		--stack-name $(AWS_STACK_NAME)

describe:
	@aws cloudformation describe-stacks \
			--region $(AWS_REGION) \
			--stack-name $(AWS_STACK_NAME) \

outputs:
	@make describe | jq -r '.Stacks[0].Outputs'

create-api:
	@aws appsync create-graphql-api \
		--name $(AWS_STACK_NAME) \
		--authentication-type API_KEY | jq

create-api-schema:
	@aws appsync start-schema-creation \
		--api-id $(API_ID) \
		--definition "$(SCHEMA)" | jq

create-api-data-source:
	@aws appsync create-data-source \
		--api-id $(API_ID) \
		--name RSSProxy \
		--type AWS_LAMBDA \
		--service-role-arn $(ROLE) \
		--lambda-config "lambdaFunctionArn=$(LAMBDA)" | jq

create-api-resolver:
	@aws appsync create-resolver \
		--api-id $(API_ID) \
		--type-name Query \
		--field-name feed \
		--data-source-name RSSProxy \
		--request-mapping-template '{ "version" : "2017-02-28", "operation": "Invoke", "payload": $$util.toJson($$context.arguments) }' \
		--response-mapping-template '$$util.toJson($$context.result)' | jq

create-api-key:
	@aws appsync create-api-key \
		--api-id $(API_ID) | jq
