import 'package:flutter/material.dart';
import '../extensions.dart';
import '../models/Note.dart';
import 'package:fleeting_notes_flutter/theme_data.dart';

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
            horizontal: Theme.of(context).own().kDefaultPadding,
            vertical: Theme.of(context).own().kDefaultPadding / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Stack(children: [
            Container(
              padding: EdgeInsets.all(Theme.of(context).own().kDefaultPadding),
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).own().kPrimaryColor
                    : Theme.of(context).own().kBgDarkColor,
                borderRadius: BorderRadius.circular(15),
              ),
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
                                    color: isActive
                                        ? Colors.white
                                        : Theme.of(context).own().kTextColor,
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
                                        color: isActive
                                            ? Colors.white
                                            : Theme.of(context)
                                                .own()
                                                .kTextColor,
                                      ),
                                ),
                            ]),
                      ),
                      SizedBox(width: Theme.of(context).own().kDefaultPadding),
                      Column(
                        children: [
                          Text(
                            note.getShortDateTimeStr(),
                            style:
                                Theme.of(context).textTheme.caption!.copyWith(
                                      color: isActive ? Colors.white70 : null,
                                    ),
                          ),
                          const SizedBox(height: 5),
                          if (note.hasAttachment) // TODO: Add attachment
                            Icon(
                              Icons.attachment,
                              size: 15,
                              color: isActive
                                  ? Colors.white70
                                  : Theme.of(context).own().kGrayColor,
                            ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ).addNeumorphism(
              blurRadius: 15,
              borderRadius: 15,
              offset: const Offset(5, 5),
              topShadowColor: Colors.white60,
              bottomShadowColor: const Color(0xFF234395).withOpacity(0.15),
            ),
          ]),
        ));
  }
}
