import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter_test_22/drawer.dart';
import 'package:flutter_test_22/apis/providers/auth_provider.dart';
import 'package:flutter_test_22/forms/invoice_form.dart';
import 'package:flutter_test_22/tabs/employee_tab.dart';
import 'package:flutter_test_22/forms/employee_form.dart';
import 'package:flutter_test_22/tabs/home_tab.dart';
import 'package:flutter_test_22/onboarding/onboarding_screen.dart';
import 'package:flutter_test_22/auth/login.dart';
import 'package:flutter_test_22/auth/signup.dart';
import 'package:flutter_test_22/auth/forgot_password.dart';
import 'package:flutter_test_22/auth/login_with_otp.dart';
import 'package:flutter_test_22/auth/otp_verification.dart';
import 'package:flutter_test_22/tabs/customersupplier_tab.dart';
import 'package:flutter_test_22/tabs/profile_pages/customer_profile_page.dart';
import 'package:flutter_test_22/tabs/profile_pages/supplier_profile_page.dart';
import 'package:flutter_test_22/forms/customersupplier_form.dart';
import 'package:flutter_test_22/inventory/inventory_list.dart';
import 'package:flutter_test_22/Inventory/inventory_form.dart';
import 'package:flutter_test_22/tabs/invoice_tab.dart';
import 'package:flutter_test_22/business_profile/business_profile_page.dart';
import 'package:flutter_test_22/business_profile/update_legal_info_form.dart';
import 'package:flutter_test_22/business_profile/update_payment_info_form.dart';
import 'package:flutter_test_22/business_profile/update_company_profile_form.dart';
import 'package:flutter_test_22/business_profile/bank_form.dart';
import 'package:flutter_test_22/business_profile/address_form.dart';
import 'package:flutter_test_22/business_profile/document_setting_form.dart';
import 'package:flutter_test_22/tabs/profile_pages/employee_profile_page.dart';
import 'package:flutter_test_22/forms/employee_profile_update_form.dart';
import 'package:flutter_test_22/tabs/profile_pages/customersupplier_profile_page.dart';
import '../../forms/customersupplier_update_form.dart';
import 'package:flutter_test_22/testing.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding',

  redirect: (context, state) {
    final container = ProviderScope.containerOf(context);
    final authState = container.read(authProvider);

    if (!authState.isInitialized) {
      return null;
    }

    final protectedRoutes = [
      '/home',
      '/employee',
      '/customersuppliers',
      '/inventory-list',
      '/inventory-form',
      '/invoice',
      '/global-home',
      '/bookmarks',
      '/business-profile',
      '/testing',
    ];

    final authRoutes = [
      '/login',
      '/signup',
      '/forgot-password',
      '/login-with-otp',
      '/otp-verification',
      '/onboarding',
    ];

    final currentPath = state.matchedLocation;
    final isProtectedRoute = protectedRoutes.any(
      (route) => currentPath.startsWith(route),
    );
    final isAuthRoute = authRoutes.contains(currentPath);

    if (!authState.isAuthenticated && isProtectedRoute) {
      return '/onboarding';
    }

    if (authState.isAuthenticated && isAuthRoute) {
      return '/home';
    }

    return null;
  },

  refreshListenable: GoRouterRefreshStream(ProviderContainer()),
  routes: [
    // Onboarding route
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/testing',
      builder: (context, state) => const CourseContentScreen(),
    ),

    // Auth routes
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/login-with-otp',
      builder: (context, state) => const LoginWithOTPScreen(),
    ),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OTPVerificationScreen(
          email: extra?['email'] ?? '',
          type: extra?['type'] ?? 'email',
          flowType: extra?['flowType'] ?? 'login-otp',
        );
      },
    ),

    GoRoute(
      path: '/global-home',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GlobalHomePage(),
    ),
    GoRoute(
      path: '/bookmarks',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BookmarksPageWithDrawer(),
    ),
    GoRoute(
      path: '/business-profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BusinessProfilePage(),
    ),
    GoRoute(
      path: '/update-company-profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const UpdateCompanyProfileForm(),
    ),
    GoRoute(
      path: '/update-payment-info',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const UpdatePaymentInfoForm(),
    ),
    GoRoute(
      path: '/update-legal-info',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const UpdateLegalInfoForm(),
    ),

    // Address and Bank routes
    GoRoute(
      path: '/add-address',
      builder: (context, state) => const AddressForm(),
    ),
    GoRoute(
      path: '/edit-address/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AddressForm(addressId: id);
      },
    ),
    GoRoute(
      path: '/add-bank-account',
      builder: (context, state) => const BankForm(),
    ),
    GoRoute(
      path: '/edit-bank-account/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BankForm(bankId: id);
      },
    ),
    GoRoute(
      path: '/add-document-setting',
      builder: (context, state) => const DocumentSettingForm(),
    ),
    GoRoute(
      path: '/edit-document-setting/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final documentTypeName = state.uri.queryParameters['documentTypeName'];
        return DocumentSettingForm(
          documentSettingId: id,
          documentTypeName: documentTypeName,
        );
      },
    ),

    // Invoice routes
    // GoRoute(
    //   path: '/invoice',
    //   parentNavigatorKey: _rootNavigatorKey,
    //   builder: (context, state) => const InvoiceTab(),
    // ),

    // Main app with bottom tabs
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeScreenWithDrawer(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeTab(),
              routes: [
                GoRoute(
                  path: 'details',
                  builder: (context, state) => const HomeDetailsPage(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inventory-list',

              builder: (context, state) => const InventoryList(),
              routes: [
                GoRoute(
                  path: 'add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => CreateInventory(),
                ),
                GoRoute(
                  path: 'edit/:id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) =>
                      CreateInventory(inventoryId: state.pathParameters['id']),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/invoice',
              builder: (context, state) => const InvoiceTab(),
              routes: [
                GoRoute(
                  path: 'add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => InvoiceFormSheet(),
                ),
                GoRoute(
                  path: 'profile/:id',
                  builder: (context, state) => EmployeeProfilePage(
                    employeeId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/employee',
              builder: (context, state) => const EmployeeTab(),
              routes: [
                // Employee creation route (for initial minimal details)
                GoRoute(
                  path: 'add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => EmployeeForm(),
                ),

                // Employee edit route (for basic edit - can be removed if not needed)
                GoRoute(
                  path: 'edit/:id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) =>
                      EmployeeForm(employeeId: state.pathParameters['id']),
                ),

                // Employee profile route
                GoRoute(
                  path: 'profile/:id',
                  builder: (context, state) => EmployeeProfilePage(
                    employeeId: state.pathParameters['id']!,
                  ),
                ),

                // Employee section-specific update routes
                GoRoute(
                  path: 'update/:id/personal',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return EmployeeSectionedFormPage(
                      employeeId: employeeId,
                      initialSection: EmployeeFormSection.personal,
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:id/contact',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return EmployeeSectionedFormPage(
                      employeeId: employeeId,
                      initialSection: EmployeeFormSection.contact,
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:id/addresses',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return EmployeeSectionedFormPage(
                      employeeId: employeeId,
                      initialSection: EmployeeFormSection.addresses,
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:id/family',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return EmployeeSectionedFormPage(
                      employeeId: employeeId,
                      initialSection: EmployeeFormSection.family,
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:id/education',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return EmployeeSectionedFormPage(
                      employeeId: employeeId,
                      initialSection: EmployeeFormSection.education,
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:id/employment',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return EmployeeSectionedFormPage(
                      employeeId: employeeId,
                      initialSection: EmployeeFormSection.employment,
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:id/salary',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return EmployeeSectionedFormPage(
                      employeeId: employeeId,
                      initialSection: EmployeeFormSection.salary,
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:id/compliance',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return EmployeeSectionedFormPage(
                      employeeId: employeeId,
                      initialSection: EmployeeFormSection.compliance,
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:id/attachments',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return EmployeeSectionedFormPage(
                      employeeId: employeeId,
                      initialSection: EmployeeFormSection.attachments,
                    );
                  },
                ),

                // Legacy route for backward compatibility (can be removed later)
                GoRoute(
                  path: 'update/:id/:section',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    final sectionStr = state.pathParameters['section']!;

                    // Convert string to enum
                    EmployeeFormSection section;
                    switch (sectionStr) {
                      case 'personal':
                        section = EmployeeFormSection.personal;
                        break;
                      case 'contact':
                        section = EmployeeFormSection.contact;
                        break;
                      case 'addresses':
                        section = EmployeeFormSection.addresses;
                        break;
                      case 'family':
                        section = EmployeeFormSection.family;
                        break;
                      case 'education':
                        section = EmployeeFormSection.education;
                        break;
                      case 'employment':
                        section = EmployeeFormSection.employment;
                        break;
                      case 'salary':
                        section = EmployeeFormSection.salary;
                        break;
                      case 'compliance':
                        section = EmployeeFormSection.compliance;
                        break;
                      case 'attachments':
                        section = EmployeeFormSection.attachments;
                        break;
                      default:
                        section = EmployeeFormSection.personal;
                    }

                    return EmployeeSectionedFormPage(
                      employeeId: employeeId,
                      initialSection: section,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/customersuppliers',
              builder: (context, state) => const CustomerSupplierTab(),
              routes: [
                GoRoute(
                  path: 'add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => CustomerFormSheet(),
                ),
                GoRoute(
                  path: 'one/:customerId',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final customerId = state.pathParameters['customerId']!;
                    final initialData = state.extra as Map<String, dynamic>?;
                    return CustomerFormSheet(
                      customerId: customerId,
                      initialData: initialData,
                    );
                  },
                ),
                // GoRoute(
                //   path: 'profile/:customerId',
                //   builder: (context, state) {
                //     final customerId = state.pathParameters['customerId']!;
                //     return CustomerProfilePage(customerId: customerId);
                //   },
                // ),
                // GoRoute(
                //   path: 'supplier/profile/:supplierId',
                //   builder: (context, state) {
                //     final supplierId = state.pathParameters['supplierId']!;
                //     return SupplierProfilePage(supplierId: supplierId);
                //   },
                // ),
                GoRoute(
                  path: 'profile/:entityId',
                  builder: (context, state) {
                    final entityId = state.pathParameters['entityId']!;
                    final entityType =
                        state.uri.queryParameters['type'] ?? 'customer';
                    return CustomerSupplierProfilePage(
                      entityId: entityId,
                      entityType: entityType,
                    );
                  },
                ),
                GoRoute(
                  path: 'update/:entityId/basic',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final entityId = state.pathParameters['entityId']!;
                    final entityType =
                        state.uri.queryParameters['type'] ?? 'customer';
                    return CustomerSupplierSectionedFormPage(
                      entityId: entityId,
                      entityType: entityType,
                      initialSection: CustomerSupplierFormSection.basic,
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:entityId/contact',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final entityId = state.pathParameters['entityId']!;
                    final entityType =
                        state.uri.queryParameters['type'] ?? 'customer';
                    return CustomerSupplierSectionedFormPage(
                      entityId: entityId,
                      entityType: entityType,
                      initialSection: CustomerSupplierFormSection.contact,
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:entityId/business',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final entityId = state.pathParameters['entityId']!;
                    final entityType =
                        state.uri.queryParameters['type'] ?? 'customer';
                    return CustomerSupplierSectionedFormPage(
                      entityId: entityId,
                      entityType: entityType,
                      initialSection: CustomerSupplierFormSection.business,
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:entityId/addresses',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final entityId = state.pathParameters['entityId']!;
                    final entityType =
                        state.uri.queryParameters['type'] ?? 'customer';
                    return CustomerSupplierSectionedFormPage(
                      entityId: entityId,
                      entityType: entityType,
                      initialSection: CustomerSupplierFormSection.addresses,
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:entityId/payment',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final entityId = state.pathParameters['entityId']!;
                    final entityType =
                        state.uri.queryParameters['type'] ?? 'customer';
                    return CustomerSupplierSectionedFormPage(
                      entityId: entityId,
                      entityType: entityType,
                      initialSection: CustomerSupplierFormSection.payment,
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:entityId/attachments',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final entityId = state.pathParameters['entityId']!;
                    final entityType =
                        state.uri.queryParameters['type'] ?? 'customer';
                    return CustomerSupplierSectionedFormPage(
                      entityId: entityId,
                      entityType: entityType,
                      initialSection: CustomerSupplierFormSection.attachments,
                    );
                  },
                ),

                // Legacy route for backward compatibility (can be removed later)
                GoRoute(
                  path: 'update/:entityId/:section',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final entityId = state.pathParameters['entityId']!;
                    final sectionStr = state.pathParameters['section']!;
                    final entityType =
                        state.uri.queryParameters['type'] ?? 'customer';

                    // Convert string to enum
                    CustomerSupplierFormSection section;
                    switch (sectionStr) {
                      case 'basic':
                        section = CustomerSupplierFormSection.basic;
                        break;
                      case 'contact':
                        section = CustomerSupplierFormSection.contact;
                        break;
                      case 'business':
                        section = CustomerSupplierFormSection.business;
                        break;
                      case 'addresses':
                        section = CustomerSupplierFormSection.addresses;
                        break;
                      case 'payment':
                        section = CustomerSupplierFormSection.payment;
                        break;
                      case 'attachments':
                        section = CustomerSupplierFormSection.attachments;
                        break;
                      default:
                        section = CustomerSupplierFormSection.basic;
                    }

                    return CustomerSupplierSectionedFormPage(
                      entityId: entityId,
                      entityType: entityType,
                      initialSection: section,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(ProviderContainer container) {
    _subscription = container.listen(authProvider, (previous, next) {
      notifyListeners();
    });
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

// Updated BookmarksPageWithDrawer with PopScope
class BookmarksPageWithDrawer extends StatelessWidget {
  const BookmarksPageWithDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !canPop) {
          // If we're on root and trying to go back, go to home instead
          context.go('/home');
        }
      },
      child: StandaloneDrawerWrapper(
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            leading: canPop
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.pop(),
                    child: const Icon(CupertinoIcons.back),
                  )
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.go('/home'),
                    child: const Icon(CupertinoIcons.home),
                  ),
            middle: const Text('Bookmarks'),
          ),
          child: SafeArea(
            child: _buildCenter(
              'Bookmarks',
              CupertinoIcons.bookmark_fill,
              CupertinoColors.systemOrange,
              context,
            ),
          ),
        ),
      ),
    );
  }
}

// Updated GlobalHomePage with PopScope
class GlobalHomePage extends StatelessWidget {
  const GlobalHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !canPop) {
          // If we're on root and trying to go back, go to home instead
          context.go('/home');
        }
      },
      child: StandaloneDrawerWrapper(
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            leading: canPop
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.pop(),
                    child: const Icon(CupertinoIcons.back),
                  )
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.go('/home'),
                    child: const Icon(CupertinoIcons.home),
                  ),
            middle: const Text('Global Home'),
          ),
          child: SafeArea(
            child: _buildCenter(
              'Global Home',
              CupertinoIcons.globe,
              CupertinoColors.systemBlue,
              context,
            ),
          ),
        ),
      ),
    );
  }
}

void _showAlert(BuildContext context) {
  showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Alert'),
      content: const Text('Proceed with destructive action?'),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('No'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Yes'),
        ),
      ],
    ),
  );
}

Widget _buildCenter(
  String title,
  IconData icon,
  Color color,
  BuildContext context,
) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          title == 'Bookmarks'
              ? 'Your saved posts and content'
              : 'Global page without tabs',
          style: const TextStyle(
            fontSize: 16,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          '← Swipe right to open drawer',
          style: TextStyle(fontSize: 14, color: CupertinoColors.systemBlue),
        ),
        const SizedBox(height: 20),
        CupertinoButton(
          onPressed: () => context.go('/home'),
          child: const Text('Go to Home'),
        ),
      ],
    ),
  );
}

// Sub-route pages
class HomeDetailsPage extends StatelessWidget {
  const HomeDetailsPage({super.key});
  @override
  Widget build(BuildContext context) => _buildSubPage('Home Details', context);
}

Widget _buildSubPage(String title, BuildContext context, {String? subtitle}) {
  return CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(middle: Text(title)),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(subtitle ?? '$title Page'),
          const Text(
            '(Drawer swipe disabled on sub-routes)',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 20),
          CupertinoButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    ),
  );
}

class CustomerFormSheet extends ConsumerWidget {
  final String? customerId;
  final Map<String, dynamic>? initialData;

  const CustomerFormSheet({super.key, this.customerId, this.initialData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomerForm(customerId: customerId, initialData: initialData);
  }
}
