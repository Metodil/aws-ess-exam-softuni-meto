import {PublishCommand, SNSClient} from "@aws-sdk/client-sns";

const sns = new SNSClient({});
const topicARN = process.env.ARN_TOPIC;

export const handler = async (event: any) => {
  console.log('Event: ', event);

  const dbInfo = event.Records[0].dynamodb
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
  ' with fileExt: '+fileExt + '\n' +
  ' with fileSize: ' + fileSize + '\n' +
  ' with dateOfUpload: '+dateOfUpload;
  console.log('Send message: ', message);

  await sns.send(new PublishCommand({
    TopicArn: topicARN,
    Message: message
  }
  ));
};
