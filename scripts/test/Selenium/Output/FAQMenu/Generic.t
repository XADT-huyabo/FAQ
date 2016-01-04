# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        # get helper object
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # get FAQ object
        my $FAQObject = $Kernel::OM->Get('Kernel::System::FAQ');

        # create test FAQ
        my $FAQTitle = 'FAQ ' . $Helper->GetRandomID();
        my $FAQID    = $FAQObject->FAQAdd(
            Title       => $FAQTitle,
            CategoryID  => 1,
            StateID     => 2,
            LanguageID  => 1,
            ValidID     => 1,
            UserID      => 1,
            ContentType => 'text/html',
        );

        # create test user and login
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users', 'faq', 'faq_admin' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get script alias
        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # navigate to AgentFAQZoom of created FAQ
        $Selenium->get("${ScriptAlias}index.pl?Action=AgentFAQZoom;ItemID=$FAQID");

        # create menu module test params
        my @MenuModule = (
            {
                Name   => "Edit",
                Action => "AgentFAQEdit;ItemID=$FAQID",
            },
            {
                Name   => "History",
                Action => "AgentFAQHistory;ItemID=$FAQID",
            },
            {
                Name   => "Print",
                Action => "AgentFAQPrint;ItemID=$FAQID",
            },
            {
                Name   => "Link",
                Action => "AgentLinkObject;SourceObject=FAQ",
            },
            {
                Name   => "Delete",
                Action => "AgentFAQDelete;ItemID=$FAQID",
            },
        );

        # check FAQ menu modules
        for my $FAQZoomMenuModule (@MenuModule) {
            $Self->True(
                $Selenium->find_element("//a[contains(\@href, \'Action=$FAQZoomMenuModule->{Action}' )]"),
                "FAQ menu $FAQZoomMenuModule->{Name} - found"
            );
        }

        # delete test created FAQ
        my $Success = $FAQObject->FAQDelete(
            ItemID => $FAQID,
            UserID => 1,
        );
        $Self->True(
            $Success,
            "$FAQTitle - deleted",
        );

        # make sure the cache is correct
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp( Type => "FAQ" );
    }
);

1;
