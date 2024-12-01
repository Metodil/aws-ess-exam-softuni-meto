"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const client_sns_1 = require("@aws-sdk/client-sns");
const client_dynamodb_1 = require("@aws-sdk/client-dynamodb");
const uuid_1 = require("uuid");
const sns = new client_sns_1.SNSClient({});
const dynamodb = new client_dynamodb_1.DynamoDBClient({});
const tableName = process.env.TABLE_NAME;
const topicARN = process.env.ARN_TOPIC;
const handler = (event) => __awaiter(void 0, void 0, void 0, function* () {
    console.log('Event: ', event);
    let responseMessage = 'Hello, AWS Lambda!';
    try {
        const bucket = event.Records[0].s3.bucket.name;
        console.log("bucket: ", bucket);
        const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
        console.log("key: ", key);
        const metaData = event.Records[0].s3.object;
        console.log("s3.object: ", metaData);
        const fileName = key;
        const fileSplit = key.split('.');
        const fileExt = fileSplit[1];
        const fileSize = event.Records[0].s3.object.size.toString();
        const dateOfUpload = event.Records[0].eventTime.toString();
        //eventName: 'ObjectCreated:Put',
        if (fileExt == "pdf" || fileExt == "jpg" || fileExt == "png") {
            // file upload ok save to base
            const ttl = Math.floor(Date.now() / 1000) + 30 * 60;
            yield dynamodb.send(new client_dynamodb_1.PutItemCommand({
                TableName: tableName,
                Item: {
                    id: {
                        S: (0, uuid_1.v4)()
                    },
                    fileName: {
                        S: fileName
                    },
                    fileSize: {
                        S: fileSize
                    },
                    fileExtension: {
                        S: fileExt
                    },
                    dateOfUpload: {
                        S: dateOfUpload
                    },
                    ttl: {
                        N: ttl.toString()
                    }
                }
            }));
        }
        else {
            //error notification
            const message = 'Error in upload.\n' +
                'The allowed extensions are ".pdf", ".jpg" and ".png" only.\n' +
                'You upload: ' + key;
            yield sns.send(new client_sns_1.PublishCommand({
                TopicArn: topicARN,
                Message: message
            }));
        }
    }
    catch (err) {
        console.log(err);
        const message = `Error getting object.`;
        console.log(message);
        throw new Error(message);
    }
});
exports.handler = handler;
