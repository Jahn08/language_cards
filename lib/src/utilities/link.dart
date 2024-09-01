import 'package:url_launcher/url_launcher.dart';
import 'context_provider.dart';

abstract class Link {
  final String url;

  const Link(this.url);

  Future<void> activate() async {
    final uri = Uri.parse(url);
    if (!(await canLaunchUrl(uri)))
      throw new Exception('A link with the $url URL cannot be launched');

    await launchUrl(uri);
  }
}

class FBLink extends Link {
  const FBLink(String userId) : super('https://www.facebook.com/$userId');
}

class EmailLink extends Link {
  const EmailLink._(super.url);

  static bool? _isHtmlSupported;

  static Future<EmailLink> build(
      {String? email, String? subject, String? body}) async {
    String? linkBody = body;
    if ((linkBody?.isNotEmpty ?? false) &&
        !(_isHtmlSupported ??
            (_isHtmlSupported = await ContextProvider.isEmailHtmlSupported()) ??
            false)) linkBody = linkBody!.replaceAll('<br>', '\n');

    return new EmailLink._('mailto:$email?subject=$subject&body=$linkBody');
  }
}

class AppStoreLink extends Link {
  AppStoreLink(String appId) : super(_buildUrl(appId));

  static String _buildUrl(String appId) =>
      'https://play.google.com/store/apps/details?id=$appId';
}
