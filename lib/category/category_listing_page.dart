import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Wareozo/apis/providers/category_provider.dart';
import 'package:Wareozo/category/category_form.dart';
import 'package:Wareozo/category/subcategory_form.dart';
import 'package:Wareozo/theme_provider.dart';

class CategoryListingPage extends ConsumerStatefulWidget {
  const CategoryListingPage({super.key});

  @override
  ConsumerState<CategoryListingPage> createState() =>
      _CategoryListingPageState();
}

class _CategoryListingPageState extends ConsumerState<CategoryListingPage> {
  final Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    // Load categories when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoriesAndSubCategories();
    });
  }

  Future<void> _loadCategoriesAndSubCategories() async {
    // First load categories
    await ref.read(categoryProvider.notifier).getCategories();

    // Then load sub-categories for each category
    final categories = ref.read(categoryProvider).categories;
    for (final category in categories) {
      final categoryId = category['_id'] as String;
      await ref.read(categoryProvider.notifier).getSubCategories(categoryId);
      // Set categories as collapsed by default
      setState(() {
        _expandedCategories[categoryId] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final colors = ref.watch(colorProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
          child: Icon(CupertinoIcons.back, color: colors.textPrimary),
        ),
        middle: Text(
          'Categories',
          style: TextStyle(
            color: colors.textPrimary,
            fontFamily: 'SF Pro Display',
            letterSpacing: 0.25,
          ),
        ),
      ),
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Error display
                if (categoryState.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: CupertinoColors.systemRed.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.exclamationmark_circle,
                          color: CupertinoColors.systemRed,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            categoryState.error!,
                            style: const TextStyle(
                              color: CupertinoColors.systemRed,
                              fontFamily: 'SF Pro Display',
                              letterSpacing: 0.25,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () =>
                              ref.read(categoryProvider.notifier).clearError(),
                          child: const Icon(
                            CupertinoIcons.xmark_circle,
                            color: CupertinoColors.systemRed,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Loading indicator
                if (categoryState.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: CupertinoActivityIndicator(),
                  ),

                // Refresh button
                if (!categoryState.isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${categoryState.categories.length} Categories',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'SF Pro Display',
                            letterSpacing: 0.25,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 32,
                          onPressed: _loadCategoriesAndSubCategories,
                          child: const Icon(
                            CupertinoIcons.refresh,
                            size: 18,
                            color: CupertinoColors.systemBlue,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Categories list
                Expanded(
                  child:
                      categoryState.categories.isEmpty &&
                          !categoryState.isLoading
                      ? _buildEmptyState(colors)
                      : _buildCategoriesList(categoryState),
                ),
              ],
            ),
          ),
          // Floating Action Button
          Positioned(
            bottom: 50,
            right: 16,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showCategoryForm(context, null),
                child: Icon(
                  CupertinoIcons.add,
                  color: CupertinoColors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(WareozeColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.folder, size: 64, color: colors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No Categories Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.25,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first category to get started',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.25,
              color: colors.textSecondary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () => _showCategoryForm(context, null),
            child: Text(
              'Add Category',
              style: TextStyle(
                color: CupertinoColors.white,
                fontFamily: 'SF Pro Display',
                letterSpacing: 0.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(CategoryState categoryState) {
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final category = categoryState.categories[index];
            final categoryId = category['_id'] as String;
            final isExpanded = _expandedCategories[categoryId] ?? false;
            final subCategories = categoryState.subCategories[categoryId] ?? [];

            return _buildCategoryCard(
              category,
              subCategories,
              isExpanded,
              categoryId,
            );
          }, childCount: categoryState.categories.length),
        ),
        // Add padding at the bottom for the floating action button
        SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildCategoryCard(
    Map<String, dynamic> category,
    List<Map<String, dynamic>> subCategories,
    bool isExpanded,
    String categoryId,
  ) {
    final colors = ref.watch(colorProvider);
    final categoryName = category['name'] as String? ?? 'Unknown';
    final categoryAlias = category['alias'] as String?;
    final createdAt = category['createdAt'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey4, width: 0.5),
      ),
      child: Column(
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category icon and name
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          CupertinoIcons.folder_fill,
                          color: colors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.25,
                                color: colors.textPrimary,
                              ),
                            ),
                            if (categoryAlias != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                categoryAlias,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'SF Pro Display',
                                  letterSpacing: 0.25,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                            if (subCategories.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${subCategories.length} sub-categories',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'SF Pro Display',
                                  letterSpacing: 0.25,
                                  color: colors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 4),
                              Text(
                                'No sub-categories',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'SF Pro Display',
                                  letterSpacing: 0.25,
                                  color: colors.textSecondary.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Row(
                  children: [
                    // Add sub-category button
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 32,
                      onPressed: () =>
                          _showSubCategoryForm(context, categoryId, null),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          CupertinoIcons.add,
                          color: CupertinoColors.systemGreen,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Edit category button
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 32,
                      onPressed: () => _showCategoryForm(context, category),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          CupertinoIcons.pencil,
                          color: CupertinoColors.systemBlue,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Expand/collapse button (always show for better UX)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 32,
                      onPressed: () => _toggleCategory(categoryId),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            CupertinoIcons.chevron_right,
                            color: CupertinoColors.systemGrey,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sub-categories list - Only show when expanded
          if (isExpanded)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: CupertinoColors.systemGrey5,
                    width: 0.5,
                  ),
                ),
              ),
              child: subCategories.isNotEmpty
                  ? Column(
                      children: [
                        // Sub-categories header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: CupertinoColors.systemGrey6.withOpacity(0.5),
                          child: Row(
                            children: [
                              const SizedBox(width: 52), // Indent for hierarchy
                              Icon(
                                CupertinoIcons.doc_text_fill,
                                color: CupertinoColors.systemOrange,
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sub-Categories (${subCategories.length})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SF Pro Display',
                                  letterSpacing: 0.25,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Sub-category items
                        ...subCategories.map((subCategory) {
                          return _buildSubCategoryTile(subCategory, categoryId);
                        }).toList(),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 52), // Indent for hierarchy
                          Icon(
                            CupertinoIcons.doc_text,
                            color: CupertinoColors.systemGrey2,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No sub-categories yet',
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'SF Pro Display',
                              letterSpacing: 0.25,
                              color: CupertinoColors.systemGrey2,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 20,
                            onPressed: () =>
                                _showSubCategoryForm(context, categoryId, null),
                            child: Text(
                              'Add first sub-category',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.25,
                                color: CupertinoColors.systemBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryTile(
    Map<String, dynamic> subCategory,
    String categoryId,
  ) {
    final subCategoryName = subCategory['name'] as String? ?? 'Unknown';
    final subCategoryAlias = subCategory['alias'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CupertinoColors.systemGrey6, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 52), // Indent for hierarchy
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: CupertinoColors.systemOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              CupertinoIcons.doc_fill,
              color: CupertinoColors.systemOrange,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subCategoryName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                  ),
                ),
                if (subCategoryAlias != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subCategoryAlias,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.25,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Edit sub-category button
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 28,
            onPressed: () =>
                _showSubCategoryForm(context, categoryId, subCategory),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                CupertinoIcons.pencil,
                color: CupertinoColors.systemBlue,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      _expandedCategories[categoryId] =
          !(_expandedCategories[categoryId] ?? false);
    });

    // Load sub-categories if expanding and not already loaded
    if (_expandedCategories[categoryId]!) {
      ref.read(categoryProvider.notifier).getSubCategories(categoryId);
    }
  }

  void _showCategoryForm(BuildContext context, Map<String, dynamic>? category) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CategoryForm(category: category),
    );
  }

  void _showSubCategoryForm(
    BuildContext context,
    String categoryId,
    Map<String, dynamic>? subCategory,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) =>
          SubCategoryForm(categoryId: categoryId, subCategory: subCategory),
    );
  }
}
