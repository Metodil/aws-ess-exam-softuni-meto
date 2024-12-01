#!/bin/bash
sudo apt update -y
sudo apt install -y nginx
# Create index.html for upload
echo '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Upload to S3</title>
</head>
<body>
    <form id="upload-form">
        <input type="file" id="file-input">
        <button type="submit">Upload File</button>
    </form>
    <script src="https://sdk.amazonaws.com/js/aws-sdk-2.813.0.min.js"></script>
    <script src="app.js"></script>
</body>
</html>' | sudo tee /var/www/html/index.html
#create app.js for upload
echo "// Configure the AWS SDK
AWS.config.region = 'eu-central-1';
AWS.config.credentials = new AWS.CognitoIdentityCredentials({
    IdentityPoolId: '<IdentityPoolId>'
});

// Create an S3 client
const s3 = new AWS.S3();

document.getElementById('upload-form').addEventListener('submit', (event) => {
    event.preventDefault();

    const fileInput = document.getElementById('file-input');
    const file = fileInput.files[0];
    if (!file) {
        alert('Please select a file to upload.');
        return;
    }

    const key = 'exam/{file.name}';
    const params = {
        Bucket: 'aws-ess-exam-meto',
        Key: key,
        Body: file
    };

    s3.putObject(params, (err, data) => {
        if (err) {
            console.error('Error uploading file:', err);
            alert('An error occurred while uploading the file.');
        } else {
            console.log('File uploaded successfully:', data);
            alert('File uploaded successfully!');
        }
    });
});" | sudo tee /var/www/html/app.js
# Update NGINX to listen on port 8080
#sudo sed -i 's/'exam/{file.name}'/`exam/${file.name}`/g' /var/www/html/app.js
# Restart NGINX to apply the changes

sudo systemctl restart nginx
