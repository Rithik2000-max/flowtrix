- [RocketChat Webhook workaround](https://github.com/wekan/univention/issues/15)

Note: Webhook to Slack and Rocket.Chat does not require adding anything to URL. Discord requires adding `/slack` to end of URL so that it works.

<img src="outgoing-webhook-discord.gif" alt="Outgoing Webhook to Discord" />

1. Add Webhook to Discord

2. On wekan board, click 3 lines "hamburger" menu / Outgoing Webhooks.

3. Add /slack to end of your Discord Webhook URL and Save URL, like this: 

```
https://discordapp.com/api/webhooks/12345/abcde/slack
```

wekan Outgoing Webhook URLs are in Slack/Rocket.Chat/Discord format.

Note: Not all wekan activities create Outgoing Webhook events. Missing activities [have been added](https://github.com/wekan/wekan/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+webhook) to [wekan Roadmap](https://github.com/wekan/wekan/projects/2). If you find some activity that does not yet have GitHub issue about it, please add new GitHub issue.

wekan uses this type of JSON when sending to Outgoing Webhook:
https://github.com/wekan/wekan/wiki/Webhook-data

Discord supports incoming webhooks in different formats, like GitHub, Slack, etc. The incoming format needs to be specified by adding webhook format to end of URL.
https://discordapp.com/developers/docs/resources/webhook#execute-slackcompatible-webhook

wekan generated webhooks are Slack compatible. Discord does not know anything about wekan, Rocket.Chat, and other apps that produce Slack compatible Outgoing Webhook format. But using any other format like GitHub etc does not work, because wekan Outgoing Webhooks are not in that format.

When making wekan Outgoing Webhook to Rocket.Chat and Slack, there is no need to add anything to Webhook URL when those that is added to wekan board. Discord in this case has decided to implement multiple Incoming Webhook formats and require specifying format in URL.

## Riot

wekan boards have Outgoing Webhooks for board change messages, those can be bridged to Riot:
https://github.com/vector-im/riot-web/issues/4978

If you have some Riot bot, you can make it call wekan REST API to make changes to wekan.
First [login to API as form data, with admin username and password](REST-API#example-call---as-form-data). Then use that Bearer token [to edit wekan](https://wekan.fi/api/).
