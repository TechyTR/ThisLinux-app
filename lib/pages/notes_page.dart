floatingActionButtonLocation:
    FloatingActionButtonLocation.endFloat,

floatingActionButton: Padding(
  padding: const EdgeInsets.only(bottom: 82),
  child: FloatingActionButton(
    onPressed: _showAddNoteDialog,
    elevation: _isGlass ? 0 : 6,
    backgroundColor: _isGlass
        ? Colors.white.withOpacity(
            _isLightGlass ? 0.38 : 0.12,
          )
        : null,
    foregroundColor:
        Theme.of(context).colorScheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: _isGlass
          ? BorderSide(
              color: _glassBorder,
              width: 1.2,
            )
          : BorderSide.none,
    ),
    child: const Icon(
      Icons.add_rounded,
      size: 28,
    ),
  ),
),

