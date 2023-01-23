import 'package:carousel_slider/carousel_slider.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/utils/responsive.dart';
import 'package:fleeting_notes_flutter/widgets/large_note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/Note.dart';
import 'note_editor_card.dart';

class NoteList extends ConsumerStatefulWidget {
  const NoteList({
    super.key,
    this.padding,
  });

  final EdgeInsetsGeometry? padding;

  @override
  ConsumerState<NoteList> createState() => _NoteListState();
}

class _NoteListState extends ConsumerState<NoteList> {
  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(viewedNotesProvider);
    final noteUtils = ref.watch(noteUtilsProvider);
    if (notes.isEmpty) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: mobileLimit),
          child: NoteEditorCard(
            note: noteUtils.cachedNote,
            elevation: 0,
            onClose: () =>
                noteUtils.onPopNote(context, noteUtils.cachedNote.id),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: (!Responsive.isMobile(context))
          ? AppBar(
              actions: [
                IconButton(
                    onPressed: (noteUtils.currPageIndex == notes.length - 1)
                        ? null
                        : noteUtils.carouselController.nextPage,
                    icon: const Icon(Icons.arrow_back)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: IconButton(
                      onPressed: (noteUtils.currPageIndex == 0)
                          ? null
                          : noteUtils.carouselController.previousPage,
                      icon: const Icon(Icons.arrow_forward)),
                ),
              ],
            )
          : null,
      body: GestureDetector(
        child: CarouselSlider.builder(
          itemCount: notes.length,
          carouselController: noteUtils.carouselController,
          options: CarouselOptions(
            height: double.infinity,
            initialPage: noteUtils.currPageIndex,
            onPageChanged: (index, reason) {
              setState(() {
                noteUtils.currPageIndex = index;
              });
            },
            scrollPhysics: (Responsive.isMobile(context))
                ? null
                : const NeverScrollableScrollPhysics(),
            viewportFraction: 0.95,
            enableInfiniteScroll: false,
            reverse: true,
          ),
          itemBuilder: (context, i, realI) {
            return Container(
                constraints: const BoxConstraints(maxWidth: mobileLimit),
                child: LargeNoteCard(note: notes[i]));
          },
        ),
      ),
    );
  }
}
