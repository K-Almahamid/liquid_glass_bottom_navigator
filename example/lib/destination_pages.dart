import 'package:flutter/material.dart';

import 'gallery_theme.dart';
import 'gallery_widgets.dart';

/// Home, with a featured note and a few calm cards.
class HomeDestination extends StatelessWidget {
  /// Creates the home destination.
  const HomeDestination({
    required this.bottomInset,
    required this.active,
    required this.dragEnabled,
    super.key,
  });

  /// Clearance above the floating bar.
  final double bottomInset;

  /// Whether home is the selected destination.
  final bool active;

  /// Whether the drag hint should be visible.
  final bool dragEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    final text = Theme.of(context).textTheme;
    return GalleryScrollView(
      key: const ValueKey('home-scroll'),
      bottomInset: bottomInset,
      children: [
        GalleryHeader(
          title: 'Home',
          showTitleKey: active,
          subtitle: 'A quiet place for notes, places, and the messages you meant to keep.',
          extra: dragEnabled
              ? Text(
                  'Hold and drag the selected tab to switch destinations.',
                  style: text.bodyLarge?.copyWith(
                    color: colors.secondary,
                    height: 1.35,
                  ),
                )
              : null,
        ),
        GalleryCard(
          color: colors.wash,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This week',
                style: text.labelLarge?.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Light on the wall',
                style: text.headlineSmall?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'A quiet room, a long table, and light moving across the wall.',
                style: text.bodyLarge?.copyWith(
                  fontSize: 17,
                  height: 1.35,
                  color: colors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        GallerySection(
          title: 'Places',
          children: [
            for (final entry in _places)
              GalleryContentTile(
                title: entry.title,
                subtitle: entry.detail,
                leading: _IconWell(icon: entry.icon),
              ),
          ],
        ),
        GallerySection(
          title: 'Notes',
          children: [
            for (final entry in _notes)
              GalleryContentTile(
                title: entry.title,
                subtitle: entry.detail,
                leading: _IconWell(icon: entry.icon),
              ),
          ],
        ),
      ],
    );
  }
}

/// Search field, suggestions, and an empty state. Filtering stays on device.
class SearchDestination extends StatefulWidget {
  /// Creates the search destination.
  const SearchDestination({
    required this.bottomInset,
    required this.active,
    super.key,
  });

  /// Clearance above the floating bar.
  final double bottomInset;

  /// Whether search is the selected destination.
  final bool active;

  @override
  State<SearchDestination> createState() => _SearchDestinationState();
}

class _SearchDestinationState extends State<SearchDestination> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    final query = _query.text.trim().toLowerCase();
    final results = query.isEmpty
        ? const <_Entry>[]
        : _catalog.where((entry) {
            return entry.title.toLowerCase().contains(query) ||
                entry.detail.toLowerCase().contains(query);
          }).toList();

    return GalleryScrollView(
      bottomInset: widget.bottomInset,
      children: [
        GalleryHeader(
          title: 'Search',
          showTitleKey: widget.active,
          subtitle: 'Look through notes, places, and messages.',
        ),
        TextField(
          key: const Key('search-field'),
          controller: _query,
          textInputAction: TextInputAction.search,
          cursorColor: colors.accent,
          onChanged: (_) => setState(() {}),
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: colors.ink),
          decoration: InputDecoration(
            hintText: 'Places, notes, messages',
            filled: true,
            fillColor: colors.card,
            prefixIcon: Icon(Icons.search, color: colors.secondary),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.accent),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 22),
        if (query.isEmpty)
          GallerySection(
            title: 'Suggestions',
            children: [
              for (final entry in _catalog.take(4))
                GalleryContentTile(
                  title: entry.title,
                  subtitle: entry.detail,
                  leading: _IconWell(icon: entry.icon),
                ),
            ],
          )
        else if (results.isEmpty)
          const _SearchEmpty()
        else
          GallerySection(
            title: 'Results',
            children: [
              for (final entry in results)
                GalleryContentTile(
                  title: entry.title,
                  subtitle: entry.detail,
                  leading: _IconWell(icon: entry.icon),
                ),
            ],
          ),
      ],
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  const _SearchEmpty();

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.search_off_outlined, size: 32, color: colors.secondary),
          const SizedBox(height: 12),
          Text(
            'No matches',
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a place, a note, or a name.',
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: colors.secondary),
          ),
        ],
      ),
    );
  }
}

/// Read and unread messages. Four are unread, matching the bar badge.
class InboxDestination extends StatelessWidget {
  /// Creates the inbox destination.
  const InboxDestination({
    required this.bottomInset,
    required this.active,
    super.key,
  });

  /// Clearance above the floating bar.
  final double bottomInset;

  /// Whether inbox is the selected destination.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final unread = _messages.where((message) => message.unread).length;
    return GalleryScrollView(
      bottomInset: bottomInset,
      children: [
        GalleryHeader(
          title: 'Inbox',
          showTitleKey: active,
          subtitle: '$unread unread',
        ),
        GallerySection(
          title: 'New',
          children: [
            for (final message in _messages.where((message) => message.unread))
              _MessageTile(message: message),
          ],
        ),
        GallerySection(
          title: 'Earlier',
          children: [
            for (final message in _messages.where((message) => !message.unread))
              _MessageTile(message: message),
          ],
        ),
      ],
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    final text = Theme.of(context).textTheme;
    return GalleryContentTile(
      title: message.subject,
      subtitle: '${message.sender} · ${message.preview}',
      emphasized: message.unread,
      showDot: message.unread,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: colors.wash,
        child: Text(
          message.sender.characters.first,
          style: text.titleSmall?.copyWith(
            color: colors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      trailing: Text(
        message.when,
        style: text.bodySmall?.copyWith(color: colors.secondary),
      ),
    );
  }
}

/// Bookmark list for the saved destination.
class SavedDestination extends StatelessWidget {
  /// Creates the saved destination.
  const SavedDestination({
    required this.bottomInset,
    required this.active,
    super.key,
  });

  /// Clearance above the floating bar.
  final double bottomInset;

  /// Whether saved is the selected destination.
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GalleryScrollView(
      bottomInset: bottomInset,
      children: [
        GalleryHeader(
          title: 'Saved',
          showTitleKey: active,
          subtitle: 'Pages and places worth returning to.',
        ),
        GallerySection(
          title: 'Bookmarks',
          children: [
            for (final entry in _saved)
              GalleryContentTile(
                title: entry.title,
                subtitle: entry.detail,
                leading: _IconWell(icon: entry.icon),
                trailing: Icon(
                  Icons.bookmark,
                  color: GalleryColors.of(context).accent,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Profile identity and grouped sample settings.
class ProfileDestination extends StatelessWidget {
  /// Creates the profile destination.
  const ProfileDestination({
    required this.bottomInset,
    required this.active,
    super.key,
  });

  /// Clearance above the floating bar.
  final double bottomInset;

  /// Whether profile is the selected destination.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    final text = Theme.of(context).textTheme;
    return GalleryScrollView(
      bottomInset: bottomInset,
      children: [
        GalleryHeader(
          title: 'Profile',
          showTitleKey: active,
          subtitle: 'The last destination is a custom avatar.',
        ),
        GalleryCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: colors.accent,
                child: Text(
                  'K',
                  style: text.headlineSmall?.copyWith(
                    color: colors.onAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kai Morgan',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keeps notes, places, and a short reading list.',
                      style: text.bodyLarge?.copyWith(
                        color: colors.secondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const GallerySection(
          title: 'Details',
          children: [
            GalleryValueRow(title: 'Name', value: 'Kai Morgan'),
            GalleryValueRow(title: 'Quiet hours', value: 'Evenings'),
            GalleryValueRow(title: 'Reading list', value: 'On this device'),
            GalleryValueRow(title: 'Language', value: 'English'),
          ],
        ),
      ],
    );
  }
}

class _IconWell extends StatelessWidget {
  const _IconWell({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.wash,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: colors.accent),
    );
  }
}

class _Entry {
  const _Entry(this.title, this.detail, this.icon);

  final String title;
  final String detail;
  final IconData icon;
}

class _Message {
  const _Message(
    this.sender,
    this.subject,
    this.preview,
    this.when,
    this.unread,
  );

  final String sender;
  final String subject;
  final String preview;
  final String when;
  final bool unread;
}

const _places = <_Entry>[
  _Entry(
    'Courtyard at dusk',
    'A short walk from the station',
    Icons.park_outlined,
  ),
  _Entry(
    'Ceramic shop',
    'The blue bowl in the window',
    Icons.storefront_outlined,
  ),
  _Entry('Train east', 'A seat by the window', Icons.train_outlined),
];

const _notes = <_Entry>[
  _Entry(
    'Blue notebook',
    'Three pages on light and rooms',
    Icons.menu_book_outlined,
  ),
  _Entry('Winter soup', 'Saved for a cold evening', Icons.restaurant_outlined),
];

const _saved = <_Entry>[
  _Entry('Courtyard at dusk', 'Place', Icons.park_outlined),
  _Entry('Blue notebook', 'Note', Icons.menu_book_outlined),
  _Entry('Train east', 'Place', Icons.train_outlined),
  _Entry('Ceramic shop', 'Place', Icons.storefront_outlined),
  _Entry('Winter soup', 'Note', Icons.restaurant_outlined),
];

const _catalog = <_Entry>[
  _Entry('Light on the wall', 'Note', Icons.wb_sunny_outlined),
  _Entry('Courtyard at dusk', 'Place', Icons.park_outlined),
  _Entry('Blue notebook', 'Note', Icons.menu_book_outlined),
  _Entry('The table by the window', 'Message', Icons.chat_bubble_outline),
  _Entry('Platform change', 'Message', Icons.chat_bubble_outline),
  _Entry('Ceramic shop', 'Place', Icons.storefront_outlined),
  _Entry('Winter soup', 'Note', Icons.restaurant_outlined),
];

const _messages = <_Message>[
  _Message(
    'Studio notes',
    'The table by the window',
    'The afternoon light sits on the long table.',
    'Now',
    true,
  ),
  _Message(
    'North line',
    'Platform change',
    'The east train leaves from the near platform.',
    '12 min',
    true,
  ),
  _Message(
    'Lina',
    'Three photos from the walk',
    'The courtyard just after the lamps came on.',
    '1 hr',
    true,
  ),
  _Message(
    'Library',
    'Held for you',
    'The blue notebook is ready to pick up.',
    'Today',
    true,
  ),
  _Message(
    'Market',
    'Short list',
    'Oranges, bread, and a small bunch of herbs.',
    'Yesterday',
    false,
  ),
  _Message(
    'Archive',
    'Tickets',
    'Saved with the other places you return to.',
    'Monday',
    false,
  ),
];
