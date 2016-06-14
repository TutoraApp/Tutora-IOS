#Tutora iOS
This is the application that we made at basehacks. If you would like to test it out follow the folliwng instructions:

#Setting up database
- Create a firebase account and replace our firebase setup with your own
- Make sure it has this structure
``` json
{
    "subjects": {
    }
}
```
#Permitting image sending
If you want to be able to send images from the ios app to the bot, you need to set up a server that can accept base64 encoded strings and convert them to URLs

#Downloading and running application
Run the following bash command:
```bash
Pod install
```
Once the pods have installed, Make sure you open xcworkspace and not xcodeproj
