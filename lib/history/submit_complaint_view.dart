import 'package:client_shared/components/back_button.dart';
import 'package:client_shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:ridy/history/history.graphql.dart';

import 'package:ridy/l10n/messages.dart';
import 'package:ridy/query_result_view.dart';

class SubmitComplaintView extends StatefulWidget {
  final String orderId;
  const SubmitComplaintView({Key? key, required this.orderId})
      : super(key: key);

  @override
  State<SubmitComplaintView> createState() => _SubmitComplaintViewState();
}

class _SubmitComplaintViewState extends State<SubmitComplaintView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? subject;
  String? content;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.only(
          top: 16,
          right: 16,
          left: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RidyBackButton(text: S.of(context).action_back),
        const SizedBox(height: 16),
        Text(S.of(context).issue_submit_title,
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(S.of(context).issue_submit_description,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                initialValue: subject,
                onChanged: (value) => setState(() {
                  subject = value;
                }),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Ionicons.ellipse,
                    color: CustomTheme.neutralColors,
                    size: 12,
                  ),
                  isDense: true,
                  hintStyle: Theme.of(context).textTheme.labelLarge,
                  hintText: S.of(context).issue_subject_placeholder,
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context).error_field_cant_be_empty;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: content,
                onChanged: (value) => setState(() {
                  content = value;
                }),
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  isDense: true,
                  hintStyle: Theme.of(context).textTheme.labelLarge,
                  hintText: S.of(context).issue_description_placeholder,
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context).error_field_cant_be_empty;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const Spacer(),
        Mutation$SubmitComplaint$Widget(
            options: WidgetOptions$Mutation$SubmitComplaint(
                onCompleted: (result, parsedData) {
                  Navigator.pop(context);
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                            content: Text(
                                S.of(context).complaint_submit_success_message),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(S.of(context).action_ok))
                            ]);
                      });
                },
                onError: (error) => showOperationErrorMessage(context, error)),
            builder: (runMutation, result) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed:
                        (content?.isEmpty ?? true) || (subject?.isEmpty ?? true)
                            ? null
                            : () {
                                runMutation(Variables$Mutation$SubmitComplaint(
                                    id: widget.orderId,
                                    subject: subject!,
                                    content: content!));
                              },
                    child: Text(S.of(context).issue_submit_button)),
              );
            })
      ]),
    );
  }
}
