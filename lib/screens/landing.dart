import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/router.dart';

@RoutePage()
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Booker"),
      ),
      body: const Center(child: OrgList()),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var repo = Provider.of<OrgRepo>(context, listen: false);
          var name = await promptForOrgName(context);
          if (name != null) {
            await repo.addOrg(name);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class OrgList extends StatelessWidget {
  const OrgList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrgRepo>(
      builder: (context, repo, child) => StreamBuilder(
        stream: repo.orgs,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Error loading organizations');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          var orgs = snapshot.data!;
          if (orgs.isEmpty) {
            return const Text('No organizations found. Please add one.');
          }
          return ListView.builder(
            itemCount: orgs.length,
            itemBuilder: (context, index) {
              var org = orgs[index];
              return Card(
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(Icons.business),
                    title: Text(org.name),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      AutoRouter.of(context).push(const HomeRoute());
                    },
                  ));
            },
          );
        },
      ),
    );
  }
}

Future<String?> promptForOrgName(BuildContext context) async {
  var controller = TextEditingController();
  var name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('Create New Organization'),
            content: TextFormField(
              autofocus: true,
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter the name of your organization',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('OK'),
              ),
            ],
          ));
  return name;
}
