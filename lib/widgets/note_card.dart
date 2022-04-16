import '../models/Note.dart';
import 'package:fleeting_notes_flutter/theme_data.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    Key? key,
    required this.note,
    required this.onTap,
    this.isActive = false,
  }) : super(key: key);

  final bool isActive;
  final VoidCallback onTap;
  final Note note;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(
            horizontal: Theme.of(context).custom.kDefaultPadding,
            vertical: Theme.of(context).custom.kDefaultPadding / 2),
        child: NeumorphicButton(
          padding: const EdgeInsets.all(0),
          style: NeumorphicStyle(
            depth: (isActive) ? 0 : 2,
            color: isActive
                ? Theme.of(context).primaryColor
                : Theme.of(context).scaffoldBackgroundColor,
            shadowLightColor: Theme.of(context).custom.lightShadow,
            shadowDarkColor: Theme.of(context).custom.darkShadow,
          ),
          onPressed: onTap,
          child: Container(
            padding: EdgeInsets.all(Theme.of(context).custom.kDefaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (note.title != '')
                              Text(
                                note.title,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isActive ? Colors.white : null,
                                ),
                              ),
                            if (note.content != '')
                              Text(
                                note.content,
                                maxLines: 2,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText2!
                                    .copyWith(
                                      color: isActive ? Colors.white : null,
                                    ),
                              ),
                          ]),
                    ),
                    SizedBox(width: Theme.of(context).custom.kDefaultPadding),
                    Column(
                      children: [
                        Text(
                          note.getShortDateTimeStr(),
                          style: Theme.of(context).textTheme.caption!.copyWith(
                                color: isActive ? Colors.white70 : null,
                              ),
                        ),
                        const SizedBox(height: 5),
                        // if (note.hasAttachment) // TODO: Add attachment
                        //   Icon(
                        //     Icons.attachment,
                        //     size: 15,
                        //     color: isActive
                        //         ? Colors.white70
                        //         : Theme.of(context).custom.kGrayColor,
                        //   ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}
