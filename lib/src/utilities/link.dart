import 'package:url_launcher/url_launcher.dart';

abstract class Link {

	final String url;

	Link(this.url);

	Future<void> activate() async {
		if (!(await canLaunch(url)))
			throw new Exception();

		await launch(url);
	}
}

class FBLink extends Link {

  	FBLink(String userId): super('https://www.facebook.com/$userId');
}

class EmailLink extends Link {

  	EmailLink({ String email, String subject, String body }): 
		super(_buildUrl(email, subject, body));

	static String _buildUrl(String email, String subject, String body) => 
		'mailto:$email?subject=$subject&body=$body';
}

class AppStoreLink extends Link {

  	AppStoreLink(String appId): super(_buildUrl(appId));

	static String _buildUrl(String appId) => 
		'https://play.google.com/store/apps/details?id=$appId';
}
