import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth
    hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roombooker_portal/router.dart';
import 'package:roombooker_core/data/repos/org_repo.dart';
import 'package:roombooker_core/data/repos/user_repo.dart';

const googleClientId =
    '610453083826-vpbosjaqm1i70nujnrq76inrtt9lbvhh.apps.googleusercontent.com';

List<AuthProvider<AuthListener, firebase_auth.AuthCredential>> providers = [
  GoogleProvider(clientId: googleClientId),
  EmailAuthProvider(),
];

var authRoutes = [
  AutoRoute(
    path: '/login/:orgID',
    page: LoginRoute.page,
    children: [
      RedirectRoute(path: '*', redirectTo: ''),
    ],
  ),
  AutoRoute(
    path: '/verify-email',
    page: EmailVerifyRoute.page,
  ),
];

@RoutePage()
class LoginScreen extends StatelessWidget {
  final String? orgID;

  const LoginScreen({super.key, @PathParam('orgID') this.orgID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: SignInScreen(
        providers: providers,
        actions: [
          ForgotPasswordAction((context, email) {
            Navigator.pushNamed(
              context,
              '/forgot-password',
              arguments: {'email': email},
            );
          }),
          VerifyPhoneAction((context, _) {
            Navigator.pushNamed(context, '/phone');
          }),
          AuthStateChangeAction<SignedIn>((context, state) async {
            final user = state.user;
            if (user == null) return;

            var router = AutoRouter.of(context);
            var userRepo = Provider.of<UserRepo>(context, listen: false);
            var orgRepo = Provider.of<OrgRepo>(context, listen: false);
            var profile = await userRepo.getUser(user.uid);
            if (profile == null) {
              await userRepo.addUser(user);
            }
            // ignore: unawaited_futures
            orgRepo.claimPendingInvites();
            if (!user.emailVerified) {
              router.push(const EmailVerifyRoute());
            } else {
              router.pop(true);
            }
          }),
          AuthStateChangeAction<UserCreated>((context, state) {
            final user = state.credential.user;
            if (user == null) return;

            final orgRepo = Provider.of<OrgRepo>(context, listen: false);
            // ignore: unawaited_futures
            orgRepo.claimPendingInvites();
            if (!user.emailVerified) {
              AutoRouter.of(context).push(const EmailVerifyRoute());
            } else {
              AutoRouter.of(context).push(const LandingRoute());
            }
          }),
          EmailLinkSignInAction((context) {
            Navigator.pushReplacementNamed(context, '/email-link-sign-in');
          }),
        ],
      ),
    );
  }
}

@RoutePage()
class EmailVerifyScreen extends StatelessWidget {
  const EmailVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmailVerificationScreen(
      actionCodeSettings: firebase_auth.ActionCodeSettings(
        url: 'https://rooms.goforthtech.org',
        handleCodeInApp: true,
      ),
      actions: [
        EmailVerifiedAction(() {
          AutoRouter.of(context).push(const LandingRoute());
        }),
        AuthCancelledAction((context) {
          FirebaseUIAuth.signOut(context: context);
          AutoRouter.of(context).push(LoginRoute());
        }),
      ],
    );
  }
}

class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    bool loggedIn = firebase_auth.FirebaseAuth.instance.currentUser != null;
    if (loggedIn) return resolver.next(true);
    bool? authenticated = await router.push(LoginRoute());
    resolver.next(authenticated ?? false);
  }
}
