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
const sns = new client_sns_1.SNSClient({});
const topicARN = process.env.ARN_TOPIC;
const handler = (event) => __awaiter(void 0, void 0, void 0, function* () {
    console.log('Event: ', event);
    const dbInfo = event.Records[0].dynamodb;
    console.log('dbInfo: ', dbInfo);
    //  dbInfo:  {
    //    ApproximateCreationDateTime: 1732705344,
    //    Keys: {
    //      fileExtension: { S: 'png' },
    //      id: { S: '3ba2951a-af3c-45da-889c-3557e96c27e8' }
    //    },
    //    NewImage: {
    //      dateOfUpload: { S: '2024-11-27T11:02:21.489Z' },
    //      fileName: { S: 'test-aws-image.png' },
    //      fileSize: { S: '68040' },
    //      fileExtension: { S: 'png' },
    const fileName = dbInfo.NewImage.fileName.S;
    const fileExt = dbInfo.NewImage.fileExtension.S;
    const fileSize = dbInfo.NewImage.fileSize.S;
    const dateOfUpload = dbInfo.NewImage.dateOfUpload.S;
    const message = 'Hi from report lambda,\nYou upload: ' + fileName + '\n' +
        ' with fileExt: ' + fileExt + '\n' +
        ' with fileSize: ' + fileSize + '\n' +
        ' with dateOfUpload: ' + dateOfUpload;
    console.log('Send message: ', message);
    yield sns.send(new client_sns_1.PublishCommand({
        TopicArn: topicARN,
        Message: message
    }));
});
exports.handler = handler;
