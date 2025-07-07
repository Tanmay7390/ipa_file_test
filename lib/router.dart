import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:Wareozo/drawer.dart';
import 'package:Wareozo/apis/providers/auth_provider.dart';
import 'package:Wareozo/forms/invoice_form.dart';
import 'package:Wareozo/tabs/employee_tab.dart';
import 'package:Wareozo/forms/employee_form.dart';
import 'package:Wareozo/tabs/home_tab.dart';
import 'package:Wareozo/onboarding/onboarding_screen.dart';
import 'package:Wareozo/auth/login.dart';
import 'package:Wareozo/auth/signup.dart';
import 'package:Wareozo/auth/forgot_password.dart';
import 'package:Wareozo/auth/login_with_otp.dart';
import 'package:Wareozo/auth/otp_verification.dart';
import 'package:Wareozo/tabs/customersupplier_tab.dart';
import 'package:Wareozo/tabs/profile_pages/customer_profile_page.dart';
import 'package:Wareozo/tabs/profile_pages/supplier_profile_page.dart';
import 'package:Wareozo/forms/customersupplier_form.dart';
import 'package:Wareozo/inventory/inventory_list.dart';
import 'package:Wareozo/Inventory/inventory_form.dart';
import 'package:Wareozo/tabs/invoice_tab.dart';
import 'package:Wareozo/business_profile/business_profile_page.dart';
import 'package:Wareozo/business_profile/update_legal_info_form.dart';
import 'package:Wareozo/business_profile/update_payment_info_form.dart';
import 'package:Wareozo/business_profile/update_company_profile_form.dart';
import 'package:Wareozo/business_profile/bank_form.dart';
import 'package:Wareozo/business_profile/address_form.dart';
import 'package:Wareozo/business_profile/document_setting_form.dart';
import 'package:Wareozo/tabs/profile_pages/employee_profile_page.dart';
import 'package:Wareozo/forms/employee_profile_update_form.dart';
import 'package:Wareozo/tabs/profile_pages/customersupplier_profile_page.dart';
import 'forms/customersupplier_profile_update_form.dart';
import 'package:Wareozo/components/exit_confirmation_utils.dart';
import 'package:Wareozo/category/category_listing_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

// Enhanced exit handling wrapper with better error handling and WillPopScope
class RobustExitWrapper extends StatefulWidget {
  final Widget child;
  final String routePath;
  final bool isMainRoute;

  const RobustExitWrapper({
    super.key,
    required this.child,
    required this.routePath,
    this.isMainRoute = false,
  });

  @override
  State<RobustExitWrapper> createState() => _RobustExitWrapperState();
}

class _RobustExitWrapperState extends State<RobustExitWrapper> {
  bool _isHandlingPop = false;

  /// Check if current route is a main tab route
  bool get _isMainTabRoute {
    return [
      '/home',
      '/employee',
      '/customersuppliers',
      '/inventory-list',
      '/invoice',
    ].contains(widget.routePath);
  }

  /// Check if should show exit confirmation
  bool get _shouldShowExitConfirmation {
    return _isMainTabRoute || widget.isMainRoute;
  }

  /// Handle back navigation with comprehensive error handling
  Future<bool> _handleWillPop() async {
    // Prevent multiple simultaneous pop attempts
    if (_isHandlingPop) {
      return false;
    }

    _isHandlingPop = true;

    try {
      if (!mounted) {
        return false;
      }

      final canPop = Navigator.of(context).canPop();
      final shouldShowExit = _shouldShowExitConfirmation;

      print('🔄 Handling back navigation:');
      print('   - Route: ${widget.routePath}');
      print('   - Can pop: $canPop');
      print('   - Should show exit: $shouldShowExit');

      if (!canPop && shouldShowExit) {
        // User is trying to exit the app from a main route
        print('   - Showing exit confirmation');
        final shouldExit = await _showExitConfirmation();
        if (shouldExit && mounted) {
          print('   - User confirmed exit');
          await _safeExit();
          return true;
        } else {
          print('   - User cancelled exit');
          return false;
        }
      } else if (canPop) {
        // Normal navigation - allow back navigation
        print('   - Normal back navigation');
        return true;
      } else {
        // User is on a non-main route but can't pop
        print('   - Navigating to home instead');
        if (mounted) {
          context.go('/home');
        }
        return false;
      }
    } catch (e) {
      print('⚠️ Error in _handleWillPop: $e');
      // In case of error, allow normal pop to prevent crash
      return true;
    } finally {
      _isHandlingPop = false;
    }
  }

  /// Show exit confirmation dialog with error handling
  Future<bool> _showExitConfirmation() async {
    try {
      if (!mounted) return false;

      return await ExitConfirmationUtils.showExitConfirmationDialog(context);
    } catch (e) {
      print('⚠️ Error showing exit confirmation: $e');
      // If dialog fails, default to not exiting
      return false;
    }
  }

  /// Safely exit the app with error handling
  Future<void> _safeExit() async {
    try {
      if (!mounted) return;

      // Add small delay for better UX
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        SystemNavigator.pop();
      }
    } catch (e) {
      print('⚠️ Error during app exit: $e');
      // Try alternative exit method
      try {
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      } catch (e2) {
        print('⚠️ Alternative exit method also failed: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: _handleWillPop, child: widget.child);
  }
}

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
      builder: (context, state) => RobustExitWrapper(
        routePath: '/onboarding',
        child: const OnboardingScreen(),
      ),
    ),

    // Auth routes
    GoRoute(
      path: '/login',
      builder: (context, state) =>
          RobustExitWrapper(routePath: '/login', child: const LoginScreen()),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) =>
          RobustExitWrapper(routePath: '/signup', child: const SignupScreen()),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => RobustExitWrapper(
        routePath: '/forgot-password',
        child: const ForgotPasswordScreen(),
      ),
    ),
    GoRoute(
      path: '/login-with-otp',
      builder: (context, state) => RobustExitWrapper(
        routePath: '/login-with-otp',
        child: const LoginWithOTPScreen(),
      ),
    ),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return RobustExitWrapper(
          routePath: '/otp-verification',
          child: OTPVerificationScreen(
            email: extra?['email'] ?? '',
            type: extra?['type'] ?? 'email',
            flowType: extra?['flowType'] ?? 'login-otp',
          ),
        );
      },
    ),

    GoRoute(
      path: '/global-home',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => RobustExitWrapper(
        routePath: '/global-home',
        isMainRoute: true,
        child: const GlobalHomePage(),
      ),
    ),
    GoRoute(
      path: '/bookmarks',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => RobustExitWrapper(
        routePath: '/bookmarks',
        isMainRoute: true,
        child: const BookmarksPageWithDrawer(),
      ),
    ),
    GoRoute(
      path: '/business-profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => RobustExitWrapper(
        routePath: '/business-profile',
        child: const BusinessProfilePage(),
      ),
    ),
    GoRoute(
      path: '/update-company-profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => RobustExitWrapper(
        routePath: '/update-company-profile',
        child: const UpdateCompanyProfileForm(),
      ),
    ),
    GoRoute(
      path: '/update-payment-info',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => RobustExitWrapper(
        routePath: '/update-payment-info',
        child: const UpdatePaymentInfoForm(),
      ),
    ),
    GoRoute(
      path: '/update-legal-info',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => RobustExitWrapper(
        routePath: '/update-legal-info',
        child: const UpdateLegalInfoForm(),
      ),
    ),

    // Address and Bank routes
    GoRoute(
      path: '/add-address',
      builder: (context, state) => RobustExitWrapper(
        routePath: '/add-address',
        child: const AddressForm(),
      ),
    ),
    GoRoute(
      path: '/edit-address/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return RobustExitWrapper(
          routePath: '/edit-address/$id',
          child: AddressForm(addressId: id),
        );
      },
    ),
    GoRoute(
      path: '/add-bank-account',
      builder: (context, state) => RobustExitWrapper(
        routePath: '/add-bank-account',
        child: const BankForm(),
      ),
    ),
    GoRoute(
      path: '/edit-bank-account/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return RobustExitWrapper(
          routePath: '/edit-bank-account/$id',
          child: BankForm(bankId: id),
        );
      },
    ),
    GoRoute(
      path: '/add-document-setting',
      builder: (context, state) => RobustExitWrapper(
        routePath: '/add-document-setting',
        child: const DocumentSettingForm(),
      ),
    ),
    GoRoute(
      path: '/edit-document-setting/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final documentTypeName = state.uri.queryParameters['documentTypeName'];
        return RobustExitWrapper(
          routePath: '/edit-document-setting/$id',
          child: DocumentSettingForm(
            documentSettingId: id,
            documentTypeName: documentTypeName,
          ),
        );
      },
    ),
    GoRoute(
      path: '/categories',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => RobustExitWrapper(
        routePath: '/categories',
        child: const CategoryListingPage(),
      ),
    ),

    // Main app with bottom tabs - Special handling for the shell route
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          RobustHomeScreenWithDrawer(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeTab(),
              routes: [
                GoRoute(
                  path: 'details',
                  builder: (context, state) => RobustExitWrapper(
                    routePath: '/home/details',
                    child: const HomeDetailsPage(),
                  ),
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
                  builder: (context, state) => RobustExitWrapper(
                    routePath: '/inventory-list/add',
                    child: CreateInventory(),
                  ),
                ),
                GoRoute(
                  path: 'edit/:id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => RobustExitWrapper(
                    routePath:
                        '/inventory-list/edit/${state.pathParameters['id']}',
                    child: CreateInventory(
                      inventoryId: state.pathParameters['id'],
                    ),
                  ),
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
                  builder: (context, state) => RobustExitWrapper(
                    routePath: '/invoice/add',
                    child: InvoiceFormSheet(),
                  ),
                ),
                GoRoute(
                  path: 'profile/:id',
                  builder: (context, state) => RobustExitWrapper(
                    routePath: '/invoice/profile/${state.pathParameters['id']}',
                    child: EmployeeProfilePage(
                      employeeId: state.pathParameters['id']!,
                    ),
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
                // Employee creation route
                GoRoute(
                  path: 'add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => RobustExitWrapper(
                    routePath: '/employee/add',
                    child: EmployeeForm(),
                  ),
                ),

                // Employee edit route
                GoRoute(
                  path: 'edit/:id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => RobustExitWrapper(
                    routePath: '/employee/edit/${state.pathParameters['id']}',
                    child: EmployeeForm(employeeId: state.pathParameters['id']),
                  ),
                ),

                // Employee profile route
                GoRoute(
                  path: 'profile/:id',
                  builder: (context, state) => RobustExitWrapper(
                    routePath:
                        '/employee/profile/${state.pathParameters['id']}',
                    child: EmployeeProfilePage(
                      employeeId: state.pathParameters['id']!,
                    ),
                  ),
                ),

                // Employee section-specific update routes
                GoRoute(
                  path: 'update/:id/personal',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return RobustExitWrapper(
                      routePath: '/employee/update/$employeeId/personal',
                      child: EmployeeSectionedFormPage(
                        employeeId: employeeId,
                        initialSection: EmployeeFormSection.personal,
                      ),
                    );
                  },
                ),

                // ... (rest of employee routes with RobustExitWrapper)
                GoRoute(
                  path: 'update/:id/contact',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return RobustExitWrapper(
                      routePath: '/employee/update/$employeeId/contact',
                      child: EmployeeSectionedFormPage(
                        employeeId: employeeId,
                        initialSection: EmployeeFormSection.contact,
                      ),
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:id/addresses',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return RobustExitWrapper(
                      routePath: '/employee/update/$employeeId/addresses',
                      child: EmployeeSectionedFormPage(
                        employeeId: employeeId,
                        initialSection: EmployeeFormSection.addresses,
                      ),
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:id/family',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return RobustExitWrapper(
                      routePath: '/employee/update/$employeeId/family',
                      child: EmployeeSectionedFormPage(
                        employeeId: employeeId,
                        initialSection: EmployeeFormSection.family,
                      ),
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:id/education',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return RobustExitWrapper(
                      routePath: '/employee/update/$employeeId/education',
                      child: EmployeeSectionedFormPage(
                        employeeId: employeeId,
                        initialSection: EmployeeFormSection.education,
                      ),
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:id/employment',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return RobustExitWrapper(
                      routePath: '/employee/update/$employeeId/employment',
                      child: EmployeeSectionedFormPage(
                        employeeId: employeeId,
                        initialSection: EmployeeFormSection.employment,
                      ),
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:id/salary',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return RobustExitWrapper(
                      routePath: '/employee/update/$employeeId/salary',
                      child: EmployeeSectionedFormPage(
                        employeeId: employeeId,
                        initialSection: EmployeeFormSection.salary,
                      ),
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:id/compliance',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return RobustExitWrapper(
                      routePath: '/employee/update/$employeeId/compliance',
                      child: EmployeeSectionedFormPage(
                        employeeId: employeeId,
                        initialSection: EmployeeFormSection.compliance,
                      ),
                    );
                  },
                ),

                GoRoute(
                  path: 'update/:id/attachments',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final employeeId = state.pathParameters['id']!;
                    return RobustExitWrapper(
                      routePath: '/employee/update/$employeeId/attachments',
                      child: EmployeeSectionedFormPage(
                        employeeId: employeeId,
                        initialSection: EmployeeFormSection.attachments,
                      ),
                    );
                  },
                ),

                // Legacy route for backward compatibility
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

                    return RobustExitWrapper(
                      routePath: '/employee/update/$employeeId/$sectionStr',
                      child: EmployeeSectionedFormPage(
                        employeeId: employeeId,
                        initialSection: section,
                      ),
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
                  builder: (context, state) => RobustExitWrapper(
                    routePath: '/customersuppliers/add',
                    child: CustomerFormSheet(),
                  ),
                ),
                GoRoute(
                  path: 'one/:customerId',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final customerId = state.pathParameters['customerId']!;
                    final initialData = state.extra as Map<String, dynamic>?;
                    return RobustExitWrapper(
                      routePath: '/customersuppliers/one/$customerId',
                      child: CustomerFormSheet(
                        customerId: customerId,
                        initialData: initialData,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'profile/:entityId',
                  builder: (context, state) {
                    final entityId = state.pathParameters['entityId']!;
                    final entityType =
                        state.uri.queryParameters['type'] ?? 'customer';
                    return RobustExitWrapper(
                      routePath: '/customersuppliers/profile/$entityId',
                      child: CustomerSupplierProfilePage(
                        entityId: entityId,
                        entityType: entityType,
                      ),
                    );
                  },
                ),
                // ... (rest of customer/supplier routes with RobustExitWrapper)
                GoRoute(
                  path: 'update/:entityId/basic',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final entityId = state.pathParameters['entityId']!;
                    final entityType =
                        state.uri.queryParameters['type'] ?? 'customer';
                    return RobustExitWrapper(
                      routePath: '/customersuppliers/update/$entityId/basic',
                      child: CustomerSupplierSectionedFormPage(
                        entityId: entityId,
                        entityType: entityType,
                        initialSection: CustomerSupplierFormSection.basic,
                      ),
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
                    return RobustExitWrapper(
                      routePath: '/customersuppliers/update/$entityId/contact',
                      child: CustomerSupplierSectionedFormPage(
                        entityId: entityId,
                        entityType: entityType,
                        initialSection: CustomerSupplierFormSection.contact,
                      ),
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
                    return RobustExitWrapper(
                      routePath: '/customersuppliers/update/$entityId/business',
                      child: CustomerSupplierSectionedFormPage(
                        entityId: entityId,
                        entityType: entityType,
                        initialSection: CustomerSupplierFormSection.business,
                      ),
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
                    return RobustExitWrapper(
                      routePath:
                          '/customersuppliers/update/$entityId/addresses',
                      child: CustomerSupplierSectionedFormPage(
                        entityId: entityId,
                        entityType: entityType,
                        initialSection: CustomerSupplierFormSection.addresses,
                      ),
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
                    return RobustExitWrapper(
                      routePath: '/customersuppliers/update/$entityId/payment',
                      child: CustomerSupplierSectionedFormPage(
                        entityId: entityId,
                        entityType: entityType,
                        initialSection: CustomerSupplierFormSection.payment,
                      ),
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
                    return RobustExitWrapper(
                      routePath:
                          '/customersuppliers/update/$entityId/attachments',
                      child: CustomerSupplierSectionedFormPage(
                        entityId: entityId,
                        entityType: entityType,
                        initialSection: CustomerSupplierFormSection.attachments,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'update/:entityId/agreedservices',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final entityId = state.pathParameters['entityId']!;
                    final entityType =
                        state.uri.queryParameters['type'] ?? 'customer';
                    return RobustExitWrapper(
                      routePath:
                          '/customersuppliers/update/$entityId/agreedservices',
                      child: CustomerSupplierSectionedFormPage(
                        entityId: entityId,
                        entityType: entityType,
                        initialSection:
                            CustomerSupplierFormSection.agreedServices,
                      ),
                    );
                  },
                ),

                // Legacy route
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
                      case 'agreedservices':
                        section = CustomerSupplierFormSection.agreedServices;
                        break;
                      default:
                        section = CustomerSupplierFormSection.basic;
                    }

                    return RobustExitWrapper(
                      routePath:
                          '/customersuppliers/update/$entityId/$sectionStr',
                      child: CustomerSupplierSectionedFormPage(
                        entityId: entityId,
                        entityType: entityType,
                        initialSection: section,
                      ),
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

// Enhanced HomeScreenWithDrawer with robust exit handling
class RobustHomeScreenWithDrawer extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const RobustHomeScreenWithDrawer({required this.navigationShell, super.key});
  @override
  State<RobustHomeScreenWithDrawer> createState() =>
      _RobustHomeScreenWithDrawerState();
}

class _RobustHomeScreenWithDrawerState extends State<RobustHomeScreenWithDrawer>
    with TickerProviderStateMixin {
  bool _isHandlingPop = false;

  /// Handle back navigation for main screen with drawer
  Future<bool> _handleMainScreenPop() async {
    // Prevent multiple simultaneous pop attempts
    if (_isHandlingPop) {
      return false;
    }

    _isHandlingPop = true;

    try {
      if (!mounted) {
        return false;
      }

      final location = GoRouterState.of(context).matchedLocation;
      final isMainTabRoute = [
        '/home',
        '/employee',
        '/customersuppliers',
        '/inventory-list',
        '/invoice',
      ].contains(location);

      print('🔄 Main screen back navigation:');
      print('   - Location: $location');
      print('   - Is main tab: $isMainTabRoute');

      if (isMainTabRoute) {
        print('   - Showing exit confirmation');
        final shouldExit = await _showExitConfirmation();
        if (shouldExit && mounted) {
          print('   - User confirmed exit');
          await _safeExit();
          return true;
        } else {
          print('   - User cancelled exit');
          return false;
        }
      } else {
        print('   - Normal navigation allowed');
        return true;
      }
    } catch (e) {
      print('⚠️ Error in main screen pop handling: $e');
      return true; // Allow normal pop to prevent crash
    } finally {
      _isHandlingPop = false;
    }
  }

  /// Show exit confirmation dialog with error handling
  Future<bool> _showExitConfirmation() async {
    try {
      if (!mounted) return false;

      return await ExitConfirmationUtils.showExitConfirmationDialog(context);
    } catch (e) {
      print('⚠️ Error showing exit confirmation: $e');
      return false;
    }
  }

  /// Safely exit the app
  Future<void> _safeExit() async {
    try {
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        SystemNavigator.pop();
      }
    } catch (e) {
      print('⚠️ Error during app exit: $e');
      try {
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      } catch (e2) {
        print('⚠️ Alternative exit method also failed: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleMainScreenPop,
      child: HomeScreenWithDrawer(navigationShell: widget.navigationShell),
    );
  }
}

// Updated standalone pages without internal PopScope since RobustExitWrapper handles it
class BookmarksPageWithDrawer extends StatelessWidget {
  const BookmarksPageWithDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return StandaloneDrawerWrapper(
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
    );
  }
}

class GlobalHomePage extends StatelessWidget {
  const GlobalHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return StandaloneDrawerWrapper(
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
