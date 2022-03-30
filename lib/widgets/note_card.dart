import 'package:flutter/material.dart';
import '../constants.dart';
import '../extensions.dart';
import '../models/Note.dart';

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
        padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Stack(children: [
            Container(
              padding: const EdgeInsets.all(kDefaultPadding),
              decoration: BoxDecoration(
                color: isActive ? kPrimaryColor : kBgDarkColor,
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
                                    color: isActive ? Colors.white : kTextColor,
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
                                            : kTextColor,
                                      ),
                                ),
                            ]),
                      ),
                      const SizedBox(width: kDefaultPadding),
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
                              color: isActive ? Colors.white70 : kGrayColor,
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
