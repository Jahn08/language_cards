import 'package:url_launcher/url_launcher.dart';
import 'context_provider.dart';

abstract class Link {

	final String url;

	Link(this.url);

	Future<void> activate() async {
		if (!(await canLaunch(url)))
			throw new Exception('A link with the $url URL cannot be launched');

		await launch(url);
	}
}

class FBLink extends Link {

  	FBLink(String userId): super('https://www.facebook.com/$userId');
}

class EmailLink extends Link {

  	EmailLink._(String url): super(url);

	static bool _isHtmlSupported;

	static Future<EmailLink> build({ String email, String subject, String body }) async {
		if ((body?.isNotEmpty ?? false) && 
			!(_isHtmlSupported ?? (_isHtmlSupported = await ContextProvider.isEmailHtmlSupported())))
			body = body.replaceAll('<br>', '\n');

		return new EmailLink._('mailto:$email?subject=$subject&body=$body');
	}
}

class AppStoreLink extends Link {

  	AppStoreLink(String appId): super(_buildUrl(appId));

	static String _buildUrl(String appId) => 
		'https://play.google.com/store/apps/details?id=$appId';
}
