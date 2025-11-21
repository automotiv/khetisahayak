import 'package:flutter/material.dart';
import '../../services/language_service.dart';

/// Language Selection Screen
///
/// Allows users to choose their preferred language (Story #376)
class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).selectLanguage),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: LanguageService.instance,
        builder: (context, _) {
          final currentLanguage = LanguageService.instance.currentLanguage;
          final languages = LanguageService.instance.supportedLanguages;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final language = languages[index];
              final isSelected = language == currentLanguage;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _getLanguageEmoji(language),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  title: Text(
                    language.nativeName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    language.englishName,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                          size: 28,
                        )
                      : Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.grey[400],
                        ),
                  onTap: () async {
                    await LanguageService.instance.setLanguage(language);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Language changed to ${language.englishName}',
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getLanguageEmoji(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'A';
      case AppLanguage.hindi:
        return 'अ';
      case AppLanguage.marathi:
        return 'अ';
    }
  }
}

/// Language Selector Widget - For inline language selection
class LanguageSelectorWidget extends StatelessWidget {
  final bool showLabel;

  const LanguageSelectorWidget({
    super.key,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final currentLanguage = LanguageService.instance.currentLanguage;

        return PopupMenuButton<AppLanguage>(
          tooltip: AppLocalizations.of(context).changeLanguage,
          onSelected: (language) {
            LanguageService.instance.setLanguage(language);
          },
          itemBuilder: (context) {
            return LanguageService.instance.supportedLanguages.map((language) {
              return PopupMenuItem<AppLanguage>(
                value: language,
                child: Row(
                  children: [
                    if (language == currentLanguage)
                      Icon(
                        Icons.check,
                        size: 18,
                        color: Theme.of(context).primaryColor,
                      )
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(language.nativeName),
                    const SizedBox(width: 8),
                    Text(
                      '(${language.englishName})',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 20),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    currentLanguage.nativeName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Language Selection Bottom Sheet
void showLanguageSelectionBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return ListenableBuilder(
        listenable: LanguageService.instance,
        builder: (context, _) {
          final currentLanguage = LanguageService.instance.currentLanguage;
          final languages = LanguageService.instance.supportedLanguages;

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context).selectLanguage,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...languages.map((language) {
                  final isSelected = language == currentLanguage;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          language == AppLanguage.english ? 'A' : 'अ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    title: Text(language.nativeName),
                    subtitle: Text(language.englishName),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).primaryColor,
                          )
                        : null,
                    onTap: () {
                      LanguageService.instance.setLanguage(language);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    },
  );
}
