import {PublishCommand, SNSClient} from "@aws-sdk/client-sns";
import {DynamoDBClient, PutItemCommand} from "@aws-sdk/client-dynamodb";
import { v4 } from "uuid";

const sns = new SNSClient({});
const dynamodb = new DynamoDBClient({});

const tableName = process.env.TABLE_NAME;
const topicARN = process.env.ARN_TOPIC;

export const handler = async (event: any) => {
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
    const fileSplit: string[] = key.split('.');
    const fileExt: string = fileSplit[1];
    const fileSize = event.Records[0].s3.object.size.toString();
    const dateOfUpload = event.Records[0].eventTime.toString();
    //eventName: 'ObjectCreated:Put',
    if( fileExt == "pdf" || fileExt == "jpg" || fileExt == "png"){
      // file upload ok save to base
      const ttl = Math.floor(Date.now()/1000)+ 30*60;
      await dynamodb.send(new PutItemCommand(
        {
          TableName: tableName,
          Item: {
            id: {
              S: v4()
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
        }
       )
      )
    } else {
      //error notification
      const message = 'Hi from image analysis lambda\n'+
        'Error in upload.\n'+
        'The allowed extensions are ".pdf", ".jpg" and ".png" only.\n'+
        'You upload: '+key
      await sns.send(new PublishCommand({
        TopicArn: topicARN,
        Message: message
      }
      ));

    }
  } catch (err) {
      console.log(err);
      const message = `Error getting object.`;
      console.log(message);
      throw new Error(message);
  }
};
