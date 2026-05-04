class PanelLoginCaptchaChallenge {
  const PanelLoginCaptchaChallenge({
    required this.captchaID,
    required this.imagePath,
    required this.attempt,
    this.errorMessage,
  });

  final String captchaID;
  final String imagePath;
  final int attempt;
  final String? errorMessage;
}

class PanelLoginCaptchaAnswer {
  const PanelLoginCaptchaAnswer({
    required this.captchaID,
    required this.captcha,
  });

  final String captchaID;
  final String captcha;
}

typedef PanelLoginCaptchaResolver = Future<String?> Function(
  PanelLoginCaptchaChallenge challenge,
);
